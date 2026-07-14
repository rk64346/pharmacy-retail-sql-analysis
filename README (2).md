# 🏥 Pharmacy Retail — Healthcare Ad-Hoc SQL Analysis

> **Domain:** Pharma Retail Analytics &nbsp;|&nbsp; **Tool:** SQL (SQLite) &nbsp;|&nbsp; **Data:** Real pharmacy sales data (Apr–Aug 2025)

---

## 📌 Problem Statement

A store manager at a leading pharmacy retail chain in Bangalore needed quick answers to business questions — which products are driving revenue, which quarter has peak demand, which sub-categories are growing — but had no structured way to query this from raw billing exports.

This project transforms **5 months of raw CSV billing data (12,000+ transactions)** into a clean star schema and answers 9 business-critical ad-hoc questions using SQL.

---

## 🗂️ Database Schema

```
fact_sales          →  Central fact table (12,174 rows)
fact_gross_price    →  Product pricing by fiscal year
fact_inventory      →  Batch-level stock & expiry data
dim_product         →  1,976 unique products (brand, dept, sub-category)
dim_customer        →  2,324 unique customers (anonymized)
dim_store           →  Store & region mapping
```

> Note: All customer names and batch numbers have been anonymized for privacy.

---

## 📊 Ad-Hoc Requests & Key Insights

### Request 1 — List all departments at the store
```sql
SELECT DISTINCT department FROM dim_product ORDER BY department;
```
**Result:** Pharma, Non Pharma, Private Label, Surgical

---

### Request 2 — Top 5 sub-categories by net sales (FY2026)

| Sub Category | Total Sales (₹) |
|---|---|
| Chronic | 4,83,068 |
| Acute | 4,07,818 |
| Personal Care | 1,17,023 |
| Endocrine & Metabolic | 1,11,739 |
| Generic | 88,382 |

> 💡 **Insight:** Chronic + Acute together contribute ~72% of total pharma revenue — confirming this is a high-prescription store.

---

### Request 3 — Quarter with maximum quantity sold (FY2026)

| Quarter | Total Qty Sold |
|---|---|
| **Q1 (Apr–Jun)** | **53,304** ✅ |
| Q2 (Jul–Sep) | 30,545 |

> 💡 **Insight:** Q1 sees the highest sales volume — likely driven by summer health needs and post-financial-year prescription renewals.

---

### Request 4 — Top 5 products by sales (FY2026)

| Product | Sales (₹) |
|---|---|
| HUMALOG MIX 50 CARTRIDGE 3ML INJ | 24,922 |
| NOVOMIX 30 PENFILL 100IU 3ML INJ | 24,049 |
| PULMOSMART 0.5MG 2ML 5S PULMULES | 20,064 |
| PAN D CAP | 17,015 |
| MONTEWOCK LC TAB | 15,787 |

> 💡 **Insight:** Top 2 products are insulin injectables — aligns with India's rising diabetic population. High-value chronic medications dominate revenue.

---

### Request 5 — Detailed sales report for a specific customer
Customer-level purchase history with product, quantity, MRP, amount, and discount applied.

---

### Request 6 — Monthly gross sales trend (FY2026)

| Month | Sales (₹) |
|---|---|
| April | 3,86,037 |
| May | 3,12,893 |
| June | 3,04,096 |
| July | 3,32,863 |
| August | 3,17,262 |

> 💡 **Insight:** April is the strongest month, followed by a gradual dip, then partial recovery in July.

---

### Request 7 — Department-wise total quantity sold

| Department | Total Qty |
|---|---|
| Pharma | 77,466 |
| Non Pharma | 4,236 |
| Private Label | 1,704 |
| Surgical | 443 |

> 💡 **Insight:** Pharma accounts for ~92% of all units sold — this is a prescription-heavy store, not a general retail outlet.

---

### Request 8 — Top 2 products per department by gross sales *(Window Function)*
Uses `ROW_NUMBER()` and `DENSE_RANK()` partitioned by department.

```sql
WITH cte1 AS (
    SELECT p.department, p.product_name,
           ROUND(SUM(f.quantity * g.gross_price), 2) AS gross_sales_total
    FROM fact_sales f
    JOIN dim_product p      ON p.product_code = f.product_code
    JOIN fact_gross_price g ON g.product_code = f.product_code
                            AND g.fiscal_year  = f.fiscal_year
    WHERE f.fiscal_year = 2026
    GROUP BY p.department, p.product_name
),
cte2 AS (
    SELECT *,
        ROW_NUMBER()  OVER (PARTITION BY department ORDER BY gross_sales_total DESC) AS rn,
        DENSE_RANK()  OVER (PARTITION BY department ORDER BY gross_sales_total DESC) AS rnk
    FROM cte1
)
SELECT department, product_name, gross_sales_total, rnk
FROM cte2 WHERE rn <= 2;
```

---

### Request 9 — Top 3 products per sub-category by quantity *(CTE + DENSE_RANK)*

```sql
WITH cte1 AS (
    SELECT p.sub_category, p.product_name,
           SUM(f.quantity) AS total_qty
    FROM fact_sales f
    JOIN dim_product p ON p.product_code = f.product_code
    WHERE f.fiscal_year = 2026
    GROUP BY p.sub_category, p.product_name
),
cte2 AS (
    SELECT *,
        DENSE_RANK() OVER (PARTITION BY sub_category ORDER BY total_qty DESC) AS drnk
    FROM cte1
)
SELECT * FROM cte2 WHERE drnk <= 3;
```

**Sample output:**

| Sub Category | Product | Qty | Rank |
|---|---|---|---|
| Acute | DOLO 650 TAB | 2,172 | 1 |
| Acute | NEUROBION FORTE TAB | 1,650 | 2 |
| Acute | PAN D CAP | 1,229 | 3 |
| Chronic | ISTAMET 50MG/500MG TAB | 940 | 1 |
| Chronic | GLYCOMET GP 2 TAB | 780 | 2 |
| Chronic | GLYCOMET 500 SR TAB | 770 | 3 |

---

## 🛠️ Tech Stack

- **SQL:** SQLite (compatible with MySQL/PostgreSQL with minor syntax changes)
- **Data Processing:** Python (pandas) — for schema normalization from raw CSVs
- **Database Design:** Star schema with 3 dimension tables + 3 fact tables

---

## 📁 Files

| File | Description |
|---|---|
| `pharmacy_adhoc_queries.sql` | All 9 ad-hoc SQL queries |
| `pharmacy_retail.db` | SQLite database (ready to query) |
| `pharmacy_retail_dump.sql` | SQL dump (import into SQLite Online) |

---

## ▶️ How to Run

**Option 1 — SQLite Online (no install needed)**
1. Go to [sqliteonline.com](https://sqliteonline.com)
2. File → Open DB → upload `pharmacy_retail.db`
3. Run any query from `pharmacy_adhoc_queries.sql`

**Option 2 — Local**
```bash
sqlite3 pharmacy_retail.db
.read pharmacy_adhoc_queries.sql
```

---

## 💡 Key SQL Concepts Used

- `JOIN` across 3+ tables
- `GROUP BY` with `SUM`, `ROUND`, `COUNT`
- `WHERE` + `HAVING` filters
- `STRFTIME()` for date-based grouping
- **CTEs** (`WITH` clause) for multi-step aggregation
- **Window Functions** — `ROW_NUMBER()`, `DENSE_RANK()` with `PARTITION BY`

---

## 👤 Author

**Rohit** — B.Pharm | GPAT Qualified | Pharma Store Operations  
Transitioning into Pharma Data Analytics | [LinkedIn](#) | [GitHub](#)
