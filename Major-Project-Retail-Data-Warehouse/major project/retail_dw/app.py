"""Flask backend: REST API exposing OLAP operations on the PostgreSQL warehouse."""
from decimal import Decimal
from flask import Flask, jsonify, render_template, request
from sqlalchemy import text
from db import engine

app = Flask(__name__)

DIMS = {"year": "d.year", "quarter": "d.quarter", "month": "d.month", "month_name": "d.month_name",
        "category": "p.category", "country": "s.store_name", "product": "p.description"}
FILTERS = {"year": ("d.year", int), "quarter": ("d.quarter", int), "month": ("d.month", int),
           "category": ("p.category", str), "country": ("s.store_name", str)}
FROM = """FROM fact_sales f
          JOIN dim_date d ON d.date_key = f.date_key
          JOIN dim_product p ON p.product_key = f.product_key
          JOIN dim_store s ON s.store_key = f.store_key"""

def where():
    """Slice = one value, dice = comma separated values. Values are bound parameters (no SQL injection)."""
    clauses, params = [], {}
    for key, (col, cast) in FILTERS.items():
        raw = request.args.get(key)
        if raw:
            try:
                params[key] = [cast(v) for v in raw.split(",")]
            except ValueError:
                continue
            clauses.append(f"{col} = ANY(:{key})")
    return ("WHERE " + " AND ".join(clauses)) if clauses else "", params

def run(sql, params):
    with engine.connect() as con:
        rows = con.execute(text(sql), params).mappings().all()
    return [{k: float(v) if isinstance(v, Decimal) else v for k, v in r.items()} for r in rows]

@app.route("/")
def index():
    return render_template("index.html")

@app.get("/api/filters")
def filters():
    q = lambda sql: [list(r.values())[0] for r in run(sql, {})]
    return jsonify(year=q("SELECT DISTINCT year FROM dim_date ORDER BY 1"),
                   category=q("SELECT DISTINCT category FROM dim_product ORDER BY 1"),
                   country=q("SELECT store_name FROM dim_store ORDER BY 1"))

@app.get("/api/kpis")
def kpis():
    w, p = where()
    return jsonify(run(f"""SELECT COALESCE(SUM(f.revenue),0) AS revenue, COALESCE(SUM(f.quantity),0) AS units,
        COUNT(DISTINCT f.invoice_no) AS orders, COUNT(DISTINCT f.customer_key) AS customers,
        COALESCE(SUM(f.revenue)/NULLIF(COUNT(DISTINCT f.invoice_no),0),0) AS avg_order {FROM} {w}""", p)[0])

@app.get("/api/olap")
def olap():
    """group=year,quarter  rollup=1 adds subtotals; filters give slice/dice; clicking a row = drill-down."""
    group = [g for g in request.args.get("group", "year").split(",") if g in DIMS]
    if not group:
        return jsonify(error="invalid group"), 400
    cols = ", ".join(f"{DIMS[g]} AS {g}" for g in group)
    by = ", ".join(DIMS[g] for g in group)
    gb = f"ROLLUP({by})" if request.args.get("rollup") == "1" else by
    w, p = where()
    return jsonify(run(f"""SELECT {cols}, SUM(f.revenue) AS revenue, SUM(f.quantity) AS units,
        COUNT(DISTINCT f.invoice_no) AS orders {FROM} {w} GROUP BY {gb} ORDER BY {by} NULLS LAST""", p))

@app.get("/api/top-products")
def top_products():
    w, p = where()
    limit = min(int(request.args.get("limit", 10)), 50)
    return jsonify(run(f"""SELECT p.description AS product, p.category, SUM(f.quantity) AS units,
        SUM(f.revenue) AS revenue {FROM} {w} GROUP BY p.description, p.category
        ORDER BY revenue DESC LIMIT {limit}""", p))

@app.get("/api/seasonal")
def seasonal():
    w, p = where()
    return jsonify(run(f"""SELECT d.month, d.month_name, SUM(f.revenue) AS revenue {FROM} {w}
        GROUP BY d.month, d.month_name ORDER BY d.month""", p))

@app.get("/api/top-customers")
def top_customers():
    w, p = where()
    return jsonify(run(f"""SELECT c.customer_id, c.country, SUM(f.revenue) AS revenue,
        COUNT(DISTINCT f.invoice_no) AS orders {FROM} JOIN dim_customer c ON c.customer_key = f.customer_key
        {w} GROUP BY c.customer_id, c.country ORDER BY revenue DESC LIMIT 10""", p))

if __name__ == "__main__":
    app.run(debug=True, port=5000)
