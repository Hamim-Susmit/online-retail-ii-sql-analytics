# Query Explanations

## `sql/00_setup.sql`
- **Business question**: Standardize raw transactions for analysis.
- **Metric definitions**: Revenue = `quantity * unit_price`; month and day derived from `invoice_date`.
- **Key SQL logic**:
  - Filters out invalid rows and cancellations.
  - Builds `retail_clean` view with consistent fields.
  - Validation query summarizes row counts and date bounds.
- **Stakeholder use**: Provides a trusted foundation for all reporting.

## `sql/01_monthly_active_customers.sql`
- **Business question**: Monthly active customers and revenue trend.
- **Metric definitions**:
  - Monthly active customers = `COUNT(DISTINCT customer_id)`
  - Orders = `COUNT(DISTINCT invoice)`
  - AOV = `total_revenue / orders`
- **Key SQL logic**: Monthly aggregation using `invoice_month` with explicit ordering.
- **Stakeholder use**: Track customer engagement and revenue health over time.

## `sql/02_retention_cohorts.sql`
- **Business question**: Do customers return after their first purchase month?
- **Metric definitions**:
  - Cohort month = first purchase month
  - Retention rate = `retained_customers / cohort_size`
- **Key SQL logic**:
  - Builds cohorts and tracks monthly activity.
  - Calculates month offsets and pivots retention to a grid.
- **Stakeholder use**: Evaluate onboarding quality and repeat purchase behavior.

## `sql/03_revenue_by_country.sql`
- **Business question**: Which countries generate the most revenue?
- **Metric definitions**: Total revenue, unique customers, and orders by country.
- **Key SQL logic**: Ranking by revenue per month using window functions.
- **Stakeholder use**: Identify geographic priorities and market concentration.

## `sql/04_top_products_by_revenue.sql`
- **Business question**: Which products drive the most revenue?
- **Metric definitions**: Total revenue, units, and orders at product level.
- **Key SQL logic**:
  - Overall top 20 products.
  - Monthly rankings with `RANK()` and filtering.
- **Stakeholder use**: Inform merchandising, pricing, and inventory decisions.

## `sql/05_exec_summary.sql`
- **Business question**: Executive KPIs and campaign targeting.
- **Metric definitions**:
  - Revenue share by country/product.
  - Month+1 retention rate.
  - At-risk high-value customer identification.
- **Key SQL logic**:
  - Combines monthly KPIs, revenue concentration, and RFM-style segmentation.
  - Uses quartiles to flag at-risk high-value customers.
- **Stakeholder use**: Provide a single-stop executive overview and actionable targeting list.
