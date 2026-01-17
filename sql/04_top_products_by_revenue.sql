-- Query 1: Top 20 products overall by revenue
SELECT
    stock_code,
    MAX(description) AS description,
    SUM(revenue) AS total_revenue,
    SUM(quantity) AS total_units,
    COUNT(DISTINCT invoice) AS orders
FROM retail_clean
GROUP BY stock_code
ORDER BY total_revenue DESC
LIMIT 20;

-- Query 2: Top 20 products by revenue per month
WITH product_monthly AS (
    SELECT
        invoice_month AS month,
        stock_code,
        MAX(description) AS description,
        SUM(revenue) AS total_revenue
    FROM retail_clean
    GROUP BY invoice_month, stock_code
), ranked AS (
    SELECT
        month,
        stock_code,
        description,
        total_revenue,
        RANK() OVER (PARTITION BY month ORDER BY total_revenue DESC) AS revenue_rank
    FROM product_monthly
)
SELECT
    month,
    stock_code,
    description,
    total_revenue,
    revenue_rank
FROM ranked
WHERE revenue_rank <= 20
ORDER BY month, revenue_rank, stock_code;
