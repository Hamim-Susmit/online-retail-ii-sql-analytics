-- =============================================================
-- Monthly Active Customers (MAC) and Revenue KPIs
-- Metrics:
--   - MAC: distinct customers with activity in the month
--   - Orders: distinct invoices in the month
--   - AOV: total_revenue / orders
--   - Orders per customer: orders / MAC
--   - Revenue per customer: total_revenue / MAC
-- =============================================================

-- Query 1: Monthly active customers
SELECT
    invoice_month AS month,
    COUNT(DISTINCT customer_id) AS monthly_active_customers
FROM retail_clean
GROUP BY invoice_month
ORDER BY invoice_month ASC;

-- Query 2: Monthly revenue KPIs
WITH monthly_metrics AS (
    SELECT
        invoice_month AS month,
        COUNT(DISTINCT customer_id) AS monthly_active_customers,
        SUM(revenue) AS total_revenue,
        COUNT(DISTINCT invoice) AS orders
    FROM retail_clean
    GROUP BY invoice_month
)
SELECT
    month,
    monthly_active_customers,
    total_revenue,
    orders,
    total_revenue / NULLIF(orders, 0) AS aov,
    orders / NULLIF(monthly_active_customers, 0) AS orders_per_customer,
    total_revenue / NULLIF(monthly_active_customers, 0) AS revenue_per_customer
FROM monthly_metrics
ORDER BY month ASC;
