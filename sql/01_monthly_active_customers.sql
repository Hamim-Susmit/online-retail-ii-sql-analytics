-- Query 1: Monthly active customers
SELECT
    invoice_month AS month,
    COUNT(DISTINCT customer_id) AS monthly_active_customers
FROM retail_clean
GROUP BY invoice_month
ORDER BY invoice_month ASC;

-- Query 2: Monthly revenue KPIs
SELECT
    invoice_month AS month,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT invoice) AS orders,
    SUM(revenue) / NULLIF(COUNT(DISTINCT invoice), 0) AS aov
FROM retail_clean
GROUP BY invoice_month
ORDER BY invoice_month ASC;
