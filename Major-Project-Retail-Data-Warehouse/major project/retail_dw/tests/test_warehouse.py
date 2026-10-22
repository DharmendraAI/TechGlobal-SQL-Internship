"""Data integrity, accuracy and performance tests. Run: pytest -v  (after ETL)"""
import time
from sqlalchemy import text
from db import engine

def one(sql):
    with engine.connect() as c:
        return c.execute(text(sql)).scalar()

def test_tables_not_empty():
    for t in ("dim_date", "dim_product", "dim_store", "dim_customer", "fact_sales"):
        assert one(f"SELECT COUNT(*) FROM {t}") > 0, t

def test_no_orphan_foreign_keys():
    for dim, key in [("dim_date", "date_key"), ("dim_product", "product_key"),
                     ("dim_store", "store_key"), ("dim_customer", "customer_key")]:
        assert one(f"SELECT COUNT(*) FROM fact_sales f LEFT JOIN {dim} d USING({key}) WHERE d.{key} IS NULL") == 0

def test_revenue_equals_qty_times_price():
    assert one("SELECT COUNT(*) FROM fact_sales WHERE ABS(revenue - quantity*unit_price) > 0.01") == 0

def test_rollup_grand_total_matches_fact_total():
    total = float(one("SELECT SUM(revenue) FROM fact_sales"))
    grand = float(one("""SELECT SUM(r) FROM (SELECT d.year, SUM(f.revenue) r FROM fact_sales f
        JOIN dim_date d ON d.date_key=f.date_key GROUP BY ROLLUP(d.year)) x WHERE year IS NULL"""))
    assert abs(total - grand) < 0.01

def test_query_performance_under_2s():
    t = time.time()
    one("""SELECT SUM(f.revenue) FROM fact_sales f JOIN dim_date d ON d.date_key=f.date_key
           JOIN dim_product p ON p.product_key=f.product_key GROUP BY CUBE(d.year, p.category) LIMIT 1""")
    assert time.time() - t < 2
