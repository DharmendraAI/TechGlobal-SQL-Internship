-- OLAP / business queries (run in pgAdmin or PyCharm Database tool)
-- 1. Roll-up: Year > Quarter > Month with subtotals and grand total
SELECT d.year, d.quarter, d.month, SUM(f.revenue) AS revenue
FROM fact_sales f JOIN dim_date d ON d.date_key = f.date_key
GROUP BY ROLLUP (d.year, d.quarter, d.month)
ORDER BY d.year, d.quarter, d.month;

-- 2. Cube: every combination of year, category, store
SELECT d.year, p.category, s.store_name, SUM(f.revenue) AS revenue
FROM fact_sales f
JOIN dim_date d ON d.date_key = f.date_key
JOIN dim_product p ON p.product_key = f.product_key
JOIN dim_store s ON s.store_key = f.store_key
GROUP BY CUBE (d.year, p.category, s.store_name);

-- 3. Drill-down: months of 2011 for one category
SELECT d.month, d.month_name, SUM(f.revenue) AS revenue
FROM fact_sales f JOIN dim_date d ON d.date_key = f.date_key
JOIN dim_product p ON p.product_key = f.product_key
WHERE d.year = 2011 AND p.category = 'Home Decor'
GROUP BY d.month, d.month_name ORDER BY d.month;

-- 4. Slice (one value) and Dice (several values)
SELECT p.category, SUM(f.revenue) FROM fact_sales f
JOIN dim_date d ON d.date_key = f.date_key JOIN dim_product p ON p.product_key = f.product_key
WHERE d.year = 2011                                   -- slice
GROUP BY p.category;
SELECT s.store_name, d.quarter, SUM(f.revenue) FROM fact_sales f
JOIN dim_date d ON d.date_key = f.date_key JOIN dim_store s ON s.store_key = f.store_key
WHERE d.quarter IN (3,4) AND s.store_name IN ('United Kingdom','Germany')  -- dice
GROUP BY s.store_name, d.quarter;

-- 5. Top-selling products
SELECT p.description, SUM(f.quantity) AS units, SUM(f.revenue) AS revenue
FROM fact_sales f JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.description ORDER BY revenue DESC LIMIT 10;

-- 6. Seasonal trend + month-over-month growth (window function)
WITH m AS (
  SELECT d.year, d.month, SUM(f.revenue) AS revenue
  FROM fact_sales f JOIN dim_date d ON d.date_key = f.date_key GROUP BY d.year, d.month)
SELECT year, month, revenue,
       ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY year, month))
             / NULLIF(LAG(revenue) OVER (ORDER BY year, month), 0), 1) AS mom_growth_pct
FROM m ORDER BY year, month;
