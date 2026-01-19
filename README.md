# Online Retail II — SQL Analytics (Supabase / PostgreSQL)

## Project Overview
This project delivers a portfolio-grade SQL analytics layer for the **Online Retail II** transactional dataset using **Supabase Postgres**. It standardizes raw transactions into a clean analytics view and answers core business questions across customer activity, retention, revenue concentration, and product performance—using SQL only.

Instead of exploratory notebooks, the focus is on how analytics teams turn raw transactions into trusted, decision-ready metrics directly in the database.

## Business Questions Answered
- How many unique customers purchase each month, and how does revenue trend over time?
- Do customers return after their first purchase month (cohort retention)?
- Which countries generate the most revenue, and how does that change month to month?
- Which products drive the most revenue overall and per month?
- If we can only run one campaign, which high-value customers are at risk?

## Dataset & Access
- **Source**: Online Retail II (UCI / Kaggle version)
- **Storage**: Raw CSV/XLSX loaded into **Supabase Postgres** (not included in this repo)
- **Input table**: `retail_transactions`
- **Analytics view**: `retail_clean` (created in `sql/00_setup.sql`)

> The dataset is intentionally **not stored** in this repository.

## Data Model & Cleaning Rules
The analytics view `retail_clean` standardizes the raw table and provides:
- normalized dates (`invoice_day`, `invoice_month`)
- consistent revenue calculation (`quantity * unit_price`)
- removal of invalid and cancellation records
- filtering of rows with missing `customer_id`

Cleaning rules applied:
- Excluded cancelled transactions (`invoice` starting with `C`)
- Removed records with non-positive `quantity` or `unit_price`
- Excluded transactions without a `customer_id`

> **Note**: Revenue represents gross sales excluding cancellations and invalid transactions. Returns are excluded rather than netted.

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

## Analytics Modules
### 1. Monthly Active Customers & Revenue Trends
- Monthly active customers (MAC)
- Total revenue and average order value (AOV)
- Month-over-month performance tracking

File: `sql/01_monthly_active_customers.sql`

### 2. Customer Retention (Cohort Analysis)
- Customers grouped by first purchase month
- Retention tracked across subsequent months
- Retention rates calculated per cohort

File: `sql/02_retention_cohorts.sql`

### 3. Revenue by Country
- Monthly revenue by country
- Ranking of top-performing markets per month

File: `sql/03_revenue_by_country.sql`

### 4. Top Products by Revenue
- Monthly product-level revenue
- Ranking of best-performing products over time

File: `sql/04_top_products_by_revenue.sql`

### 5. Executive Summary & Campaign Targeting
A consolidated, leadership-style summary including:
- Monthly KPIs (customers, orders, revenue, AOV)
- Customer segmentation using recency and monetary value
- Identification of high-value but at-risk customers for targeted campaigns

File: `sql/05_exec_summary.sql`

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
