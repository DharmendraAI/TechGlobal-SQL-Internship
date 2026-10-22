"""ETL: CSV (Kaggle ecommerce-data format) -> PostgreSQL star schema.
Usage:  python etl/etl.py [path_to_csv]"""
import sys
from pathlib import Path
import pandas as pd
from sqlalchemy import text

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
from db import engine                       # noqa: E402
from etl.generate_data import generate      # noqa: E402

DEFAULT_CSV = ROOT / "data" / "retail_sales.csv"
CATS = {"BAG": "Bags", "LIGHT": "Lighting", "LANTERN": "Lighting", "CANDLE": "Lighting",
        "MUG": "Kitchen", "CUP": "Kitchen", "BOWL": "Kitchen", "PLATE": "Kitchen", "JAR": "Kitchen",
        "CAKE": "Kitchen", "CARD": "Stationery", "PAPER": "Stationery", "NOTEBOOK": "Stationery",
        "PEN": "Stationery", "FRAME": "Home Decor", "CLOCK": "Home Decor", "CUSHION": "Home Decor",
        "SIGN": "Home Decor", "BOX": "Storage", "TIN": "Storage", "BASKET": "Storage",
        "DOLL": "Toys", "TOY": "Toys", "GAME": "Toys"}

def category(desc):
    for w in desc.split():
        if w in CATS:
            return CATS[w]
    return "Other"

def extract(path):
    if not path.exists():
        print("CSV not found - generating sample data")
        path.parent.mkdir(exist_ok=True)
        generate().to_csv(path, index=False)
    df = pd.read_csv(path, encoding="ISO-8859-1", dtype={"InvoiceNo": str, "StockCode": str})
    print(f"Extracted {len(df):,} rows")
    return df

def transform(df):
    df = df.dropna(subset=["CustomerID", "Description"]).copy()
    df = df[~df["InvoiceNo"].str.startswith("C")]                       # cancellations
    df = df[(df["Quantity"] > 0) & (df["UnitPrice"] > 0)].drop_duplicates()
    df["CustomerID"] = df["CustomerID"].astype(int)
    df["StockCode"] = df["StockCode"].str.strip().str.upper()
    df["Description"] = df["Description"].str.strip().str.upper()
    df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"])
    df["full_date"] = df["InvoiceDate"].dt.normalize()
    df["revenue"] = (df["Quantity"] * df["UnitPrice"]).round(2)

    dates = pd.DataFrame({"full_date": pd.date_range(df.full_date.min(), df.full_date.max())})
    dates["date_key"] = dates.full_date.dt.strftime("%Y%m%d").astype(int)
    dates["day"], dates["month"] = dates.full_date.dt.day, dates.full_date.dt.month
    dates["month_name"] = dates.full_date.dt.strftime("%b")
    dates["quarter"], dates["year"] = dates.full_date.dt.quarter, dates.full_date.dt.year
    dates["day_name"] = dates.full_date.dt.strftime("%a")
    dates["is_weekend"] = dates.full_date.dt.dayofweek >= 5

    prod = df.groupby("StockCode", as_index=False)["Description"].first()
    prod.columns = ["stock_code", "description"]
    prod["category"] = prod["description"].map(category)
    prod.insert(0, "product_key", range(1, len(prod) + 1))

    stores = pd.DataFrame({"store_name": sorted(df.Country.unique())})
    stores["region"] = stores.store_name.map(lambda c: "Domestic" if c == "United Kingdom" else "International")
    stores.insert(0, "store_key", range(1, len(stores) + 1))

    cust = df.drop_duplicates("CustomerID")[["CustomerID", "Country"]]
    cust.columns = ["customer_id", "country"]
    cust.insert(0, "customer_key", range(1, len(cust) + 1))

    fact = (df.merge(dates[["full_date", "date_key"]], on="full_date")
              .merge(prod[["stock_code", "product_key"]], left_on="StockCode", right_on="stock_code")
              .merge(stores[["store_name", "store_key"]], left_on="Country", right_on="store_name")
              .merge(cust[["customer_id", "customer_key"]], left_on="CustomerID", right_on="customer_id"))
    fact = fact.rename(columns={"InvoiceNo": "invoice_no", "Quantity": "quantity", "UnitPrice": "unit_price"})
    fact = fact[["invoice_no", "date_key", "product_key", "store_key", "customer_key",
                 "quantity", "unit_price", "revenue"]]
    print(f"Transformed -> fact rows: {len(fact):,}")
    dates = dates.assign(full_date=dates.full_date.dt.date)
    return dates, prod, stores, cust, fact

def load(dates, prod, stores, cust, fact):
    with engine.begin() as con:
        con.execute(text((ROOT / "sql" / "schema.sql").read_text()))
        for name, frame in [("dim_date", dates), ("dim_product", prod), ("dim_store", stores),
                            ("dim_customer", cust)]:
            frame.to_sql(name, con, if_exists="append", index=False, method="multi", chunksize=5000)
        fact.to_sql("fact_sales", con, if_exists="append", index=False, method="multi", chunksize=5000)
    print("Load complete")

if __name__ == "__main__":
    load(*transform(extract(Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_CSV)))
