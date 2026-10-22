-- Star schema for Retail Sales Data Warehouse (PostgreSQL)
DROP TABLE IF EXISTS fact_sales, dim_date, dim_product, dim_store, dim_customer CASCADE;

CREATE TABLE dim_date (
    date_key    INT PRIMARY KEY,              -- yyyymmdd
    full_date   DATE NOT NULL UNIQUE,
    day         SMALLINT NOT NULL,
    month       SMALLINT NOT NULL,
    month_name  VARCHAR(10) NOT NULL,
    quarter     SMALLINT NOT NULL,
    year        SMALLINT NOT NULL,
    day_name    VARCHAR(10) NOT NULL,
    is_weekend  BOOLEAN NOT NULL
);
CREATE TABLE dim_product (
    product_key INT PRIMARY KEY,
    stock_code  VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL,
    category    VARCHAR(40) NOT NULL
);
CREATE TABLE dim_store (
    store_key   INT PRIMARY KEY,
    store_name  VARCHAR(60) NOT NULL UNIQUE,  -- one store per country
    region      VARCHAR(20) NOT NULL
);
CREATE TABLE dim_customer (
    customer_key INT PRIMARY KEY,
    customer_id  INT NOT NULL UNIQUE,
    country      VARCHAR(60) NOT NULL
);
CREATE TABLE fact_sales (
    sales_key    BIGSERIAL PRIMARY KEY,
    invoice_no   VARCHAR(20) NOT NULL,
    date_key     INT NOT NULL REFERENCES dim_date(date_key),
    product_key  INT NOT NULL REFERENCES dim_product(product_key),
    store_key    INT NOT NULL REFERENCES dim_store(store_key),
    customer_key INT NOT NULL REFERENCES dim_customer(customer_key),
    quantity     INT NOT NULL CHECK (quantity > 0),
    unit_price   NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    revenue      NUMERIC(12,2) NOT NULL
);
CREATE INDEX ix_fact_date     ON fact_sales(date_key);
CREATE INDEX ix_fact_product  ON fact_sales(product_key);
CREATE INDEX ix_fact_store    ON fact_sales(store_key);
CREATE INDEX ix_fact_customer ON fact_sales(customer_key);
