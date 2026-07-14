-- ============================================================
--  ASTER PHARMACY — Healthcare Ad-Hoc SQL Project
--  Data: Apr–Aug 2025 | Store: KA - JPNAGAR 5TH PHASE
--  Schema: dim_product, dim_store, dim_customer,
--          fact_sales, fact_inventory, fact_gross_price
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- #ad_hoc_request_1
-- List all unique departments (product categories) sold at
-- Leading Pharmacy Retail Chain, JPNAGAR branch.
-- ─────────────────────────────────────────────────────────────
SELECT DISTINCT department
FROM dim_product
ORDER BY department;


-- ─────────────────────────────────────────────────────────────
-- #ad_hoc_request_2
-- Top 5 sub-categories by total sales amount in FY2026.
-- Final output: sub_category, total_sales
-- ─────────────────────────────────────────────────────────────
SELECT
    p.sub_category,
    ROUND(SUM(f.amount), 2) AS total_sales
FROM fact_sales f
JOIN dim_product p ON p.product_code = f.product_code
WHERE f.fiscal_year = 2026
GROUP BY p.sub_category
ORDER BY total_sales DESC
LIMIT 5;


-- ─────────────────────────────────────────────────────────────
-- #ad_hoc_request_3
-- In which fiscal quarter (Q1=Apr-Jun, Q2=Jul-Sep) was the
-- maximum quantity of medicines sold in FY2026?
-- Final output: quarter, total_sold_qty
-- ─────────────────────────────────────────────────────────────
SELECT
    quarter,
    SUM(quantity) AS total_sold_qty
FROM fact_sales
WHERE fiscal_year = 2026
GROUP BY quarter
ORDER BY total_sold_qty DESC;


-- ─────────────────────────────────────────────────────────────
-- #ad_hoc_request_4
-- Top 5 products by total sales amount in FY2026.
-- Final output: product_name, total_sales
-- ─────────────────────────────────────────────────────────────
SELECT
    p.product_name,
    ROUND(SUM(f.amount), 2) AS total_sales
FROM fact_sales f
JOIN dim_product p ON p.product_code = f.product_code
WHERE f.fiscal_year = 2026
GROUP BY p.product_name
ORDER BY total_sales DESC
LIMIT 5;


-- ─────────────────────────────────────────────────────────────
-- #ad_hoc_request_5
-- Detailed sales report for a specific customer (e.g. customer_code = 59246).
-- Final output: bill_date, product_name, sub_category, quantity,
--               mrp, amount, disc_pct
-- ─────────────────────────────────────────────────────────────
SELECT
    f.bill_date,
    p.product_name,
    p.sub_category,
    f.quantity,
    f.mrp,
    f.amount,
    f.disc_pct
FROM fact_sales f
JOIN dim_product p ON p.product_code = f.product_code
WHERE f.customer_code = 59246
ORDER BY f.bill_date ASC;


-- ─────────────────────────────────────────────────────────────
-- #ad_hoc_request_6
-- Monthly gross sales trend for the store in FY2026.
-- Final output: month_number, monthly_gross_sales
-- ─────────────────────────────────────────────────────────────
SELECT
    STRFTIME('%m', bill_date)       AS month_number,
    ROUND(SUM(amount), 1)           AS monthly_gross_sales
FROM fact_sales
WHERE fiscal_year = 2026
GROUP BY month_number
ORDER BY month_number;


-- ─────────────────────────────────────────────────────────────
-- #ad_hoc_request_7
-- Total quantity sold per department in FY2026.
-- Final output: department, total_qty
-- ─────────────────────────────────────────────────────────────
SELECT
    p.department,
    SUM(f.quantity) AS total_qty
FROM fact_sales f
JOIN dim_product p ON p.product_code = f.product_code
WHERE f.fiscal_year = 2026
GROUP BY p.department
ORDER BY total_qty DESC;


-- ─────────────────────────────────────────────────────────────
-- #ad_hoc_request_8
-- Top 2 products in every department by gross sales in FY2026.
-- Uses CTE + Window Function (ROW_NUMBER + DENSE_RANK).
-- Final output: department, product_name, gross_sales, rnk
-- ─────────────────────────────────────────────────────────────
WITH cte1 AS (
    SELECT
        p.department,
        p.product_name,
        ROUND(SUM(f.quantity * g.gross_price), 2)           AS gross_sales_total
    FROM fact_sales f
    JOIN dim_product p      ON p.product_code = f.product_code
    JOIN fact_gross_price g ON g.product_code = f.product_code
                            AND g.fiscal_year  = f.fiscal_year
    WHERE f.fiscal_year = 2026
    GROUP BY p.department, p.product_name
),
cte2 AS (
    SELECT
        *,
        ROW_NUMBER()  OVER (PARTITION BY department ORDER BY gross_sales_total DESC) AS rn,
        DENSE_RANK()  OVER (PARTITION BY department ORDER BY gross_sales_total DESC) AS rnk
    FROM cte1
)
SELECT department, product_name, gross_sales_total, rnk
FROM cte2
WHERE rn <= 2;


-- ─────────────────────────────────────────────────────────────
-- #ad_hoc_request_9
-- Top 3 products by quantity sold within each sub_category
-- in FY2026. Uses CTE + DENSE_RANK window function.
-- Final output: sub_category, product_name, total_qty, drnk
-- ─────────────────────────────────────────────────────────────
WITH cte1 AS (
    SELECT
        p.sub_category,
        p.product_name,
        SUM(f.quantity) AS total_qty
    FROM fact_sales f
    JOIN dim_product p ON p.product_code = f.product_code
    WHERE f.fiscal_year = 2026
    GROUP BY p.sub_category, p.product_name
),
cte2 AS (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY sub_category ORDER BY total_qty DESC) AS drnk
    FROM cte1
)
SELECT *
FROM cte2
WHERE drnk <= 3;
