# Online Retail II — SQL Analytics (Supabase / PostgreSQL)

## Project Overview
This project delivers a portfolio-grade SQL analytics layer for the **Online Retail II** transactional dataset using **Supabase Postgres**. It standardizes raw transactions into a clean analytics view and answers core business questions across customer activity, retention, revenue concentration, and product performance—using SQL only.

## Business Questions Answered
- How many unique customers purchase each month, and how does revenue trend over time?
- Do customers return after their first purchase month (cohort retention)?
- Which countries generate the most revenue, and how does that change month to month?
- Which products drive the most revenue overall and per month?
- If we can only run one campaign, which high-value customers are at risk?

## Dataset & Access
- **Source**: Online Retail II (UCI / Kaggle version)
- **Storage**: Raw CSV/XLSX is loaded into **Supabase Postgres** (not included in this repo).
- **Input table**: `retail_transactions`
- **Analytics view**: `retail_clean` (created in `sql/00_setup.sql`)

> The dataset is intentionally **not stored** in this repository.

## Data Model
The analytics view `retail_clean` standardizes the raw table and provides:
- normalized dates (`invoice_day`, `invoice_month`)
- consistent revenue calculation
- removal of invalid and cancellation records
- filtering of rows with missing `customer_id`

## How to Run (Supabase SQL Editor Workflow)
1. Load the raw dataset into Supabase as `retail_transactions`.
2. Open the Supabase SQL Editor.
3. Run the SQL files in order:
   - `sql/00_setup.sql`
   - `sql/01_monthly_active_customers.sql`
   - `sql/02_retention_cohorts.sql`
   - `sql/03_revenue_by_country.sql`
   - `sql/04_top_products_by_revenue.sql`
   - `sql/05_exec_summary.sql`

Each file is self-contained and can be rerun safely.

## Key Metrics Defined
- **Monthly Active Customers (MAC)**: `COUNT(DISTINCT customer_id)` per month
- **Orders**: `COUNT(DISTINCT invoice)`
- **Revenue**: `quantity * unit_price`
- **AOV**: `total_revenue / orders`
- **Retention Rate**: `retained_customers / cohort_size`

## “If we can only do one campaign…”
The executive summary file includes a targeting query that identifies **At Risk High-Value** customers:
- **Recency** in the worst (highest) quartile
- **Monetary value** in the top quartile

These customers are prioritized for a win-back campaign.

## Assumptions
- `invoice` values beginning with `C` indicate cancellations/returns.
- Records with `quantity <= 0`, `unit_price <= 0`, or `customer_id IS NULL` are excluded.
- The SQL is written for **PostgreSQL/Supabase** and uses standard functions like `DATE_TRUNC`.

## Suggested Next Steps
- Add margin or COGS data to analyze profitability, not just revenue.
- Extend retention analysis to 12 months and segment by country or product category.
- Build a lightweight BI dashboard on top of these queries.
