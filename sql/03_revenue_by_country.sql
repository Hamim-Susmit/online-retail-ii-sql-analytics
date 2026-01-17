-- Query 1: Revenue by country
SELECT
    country,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT invoice) AS orders
FROM retail_clean
GROUP BY country
ORDER BY total_revenue DESC;

-- Query 2: Monthly top 10 countries by revenue
WITH country_monthly AS (
    SELECT
        invoice_month AS month,
        country,
        SUM(revenue) AS total_revenue
    FROM retail_clean
    GROUP BY invoice_month, country
), ranked AS (
    SELECT
        month,
        country,
        total_revenue,
        RANK() OVER (PARTITION BY month ORDER BY total_revenue DESC) AS revenue_rank
    FROM country_monthly
)
SELECT
    month,
    country,
    total_revenue,
    revenue_rank
FROM ranked
WHERE revenue_rank <= 10
ORDER BY month, revenue_rank, country;
