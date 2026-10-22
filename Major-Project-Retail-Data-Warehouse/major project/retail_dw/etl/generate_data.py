"""Creates a realistic sample file (same columns as Kaggle carrie1/ecommerce-data)
so the project runs even without downloading the dataset."""
import numpy as np, pandas as pd
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "data" / "retail_sales.csv"

def generate(n=60000, seed=42):
    rng = np.random.default_rng(seed)
    adj = ["VINTAGE", "RED", "BLUE", "PINK", "WOODEN", "RETRO", "CERAMIC", "GLASS", "FLORAL", "STRIPED"]
    noun = ["MUG", "BAG", "CANDLE", "LANTERN", "FRAME", "CLOCK", "CUSHION", "CARD", "NOTEBOOK", "BOX",
            "TIN", "BASKET", "DOLL", "BOWL", "SIGN", "JAR"]
    prods = [(f"P{1000+i}", f"{a} {n_}") for i, (a, n_) in enumerate((a, n_) for a in adj for n_ in noun)]
    price = rng.choice([0.85, 1.25, 1.95, 2.95, 3.75, 4.95, 7.95, 12.5], size=len(prods))
    days = pd.date_range("2010-12-01", "2011-12-09")
    season = np.array([1.0 + (0.9 if d.month in (10, 11) else 0.3 if d.month == 12 else 0) for d in days])
    day_idx = rng.choice(len(days), size=n, p=season / season.sum())
    countries = ["United Kingdom", "Germany", "France", "Spain", "Netherlands", "Australia", "Ireland"]
    cust_ids = np.arange(12346, 12346 + 1500)
    cust_country = rng.choice(countries, size=len(cust_ids), p=[.8, .06, .05, .03, .02, .02, .02])
    c = rng.integers(0, len(cust_ids), size=n)
    p = rng.integers(0, len(prods), size=n)
    secs = rng.integers(8 * 3600, 18 * 3600, size=n)
    dt = days[day_idx] + pd.to_timedelta(secs, unit="s")
    df = pd.DataFrame({
        "InvoiceNo": (536000 + (day_idx * 40 + c % 40)).astype(str),
        "StockCode": [prods[i][0] for i in p],
        "Description": [prods[i][1] for i in p],
        "Quantity": rng.choice([1, 2, 3, 4, 6, 8, 12, 24], size=n, p=[.2, .2, .15, .15, .1, .08, .08, .04]),
        "InvoiceDate": dt.strftime("%Y-%m-%d %H:%M:%S"),
        "UnitPrice": price[p],
        "CustomerID": cust_ids[c].astype(float),
        "Country": cust_country[c],
    })
    df.loc[rng.choice(n, 300, replace=False), "CustomerID"] = np.nan          # dirty rows for ETL to clean
    df.loc[rng.choice(n, 150, replace=False), "Quantity"] = -1                # returns
    return df

if __name__ == "__main__":
    OUT.parent.mkdir(exist_ok=True)
    generate().to_csv(OUT, index=False)
    print("Sample dataset written to", OUT)
