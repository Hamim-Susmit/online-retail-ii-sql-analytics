-- Query 1: Monthly KPIs
SELECT
    invoice_month AS month,
    COUNT(DISTINCT customer_id) AS monthly_active_customers,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT invoice) AS orders,
    SUM(revenue) / NULLIF(COUNT(DISTINCT invoice), 0) AS aov
FROM retail_clean
GROUP BY invoice_month
ORDER BY invoice_month;

-- Query 2: Top 10 countries by revenue share
WITH country_revenue AS (
    SELECT
        country,
        SUM(revenue) AS total_revenue
    FROM retail_clean
    GROUP BY country
)
SELECT
    country,
    total_revenue,
    total_revenue / NULLIF(SUM(total_revenue) OVER (), 0) AS revenue_share
FROM country_revenue
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 3: Top 10 products by revenue share
WITH product_revenue AS (
    SELECT
        stock_code,
        MAX(description) AS description,
        SUM(revenue) AS total_revenue
    FROM retail_clean
    GROUP BY stock_code
)
SELECT
    stock_code,
    description,
    total_revenue,
    total_revenue / NULLIF(SUM(total_revenue) OVER (), 0) AS revenue_share
FROM product_revenue
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 4: Month+1 retention summary
WITH customer_cohorts AS (
    SELECT
        customer_id,
        MIN(invoice_month) AS cohort_month
    FROM retail_clean
    GROUP BY customer_id
), cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
), cohort_activity AS (
    SELECT
        rc.customer_id,
        cc.cohort_month,
        rc.invoice_month AS activity_month,
        (EXTRACT(YEAR FROM rc.invoice_month) - EXTRACT(YEAR FROM cc.cohort_month)) * 12
        + (EXTRACT(MONTH FROM rc.invoice_month) - EXTRACT(MONTH FROM cc.cohort_month))
            AS months_since
    FROM retail_clean rc
    INNER JOIN customer_cohorts cc
        ON rc.customer_id = cc.customer_id
), retained AS (
    SELECT
        cohort_month,
        months_since,
        COUNT(DISTINCT customer_id) AS retained_customers
    FROM cohort_activity
    GROUP BY cohort_month, months_since
)
SELECT
    cs.cohort_month,
    cs.cohort_size,
    COALESCE(r.retained_customers, 0) AS retained_m1,
    COALESCE(r.retained_customers, 0)::numeric / NULLIF(cs.cohort_size, 0) AS retention_rate_m1
FROM cohort_sizes cs
LEFT JOIN retained r
    ON cs.cohort_month = r.cohort_month
    AND r.months_since = 1
ORDER BY cs.cohort_month;

-- Query 5: Campaign targeting table (At Risk High-Value)
WITH customer_metrics AS (
    SELECT
        customer_id,
        MIN(invoice_date::date) AS first_purchase_date,
        MAX(invoice_date::date) AS last_purchase_date,
        (CURRENT_DATE - MAX(invoice_date::date))::integer AS recency_days,
        COUNT(DISTINCT invoice) AS frequency_orders,
        SUM(revenue) AS monetary_revenue
    FROM retail_clean
    GROUP BY customer_id
), scored AS (
    SELECT
        customer_id,
        first_purchase_date,
        last_purchase_date,
        recency_days,
        frequency_orders,
        monetary_revenue,
        NTILE(4) OVER (ORDER BY recency_days ASC) AS recency_quartile,
        NTILE(4) OVER (ORDER BY monetary_revenue ASC) AS monetary_quartile
    FROM customer_metrics
)
SELECT
    customer_id,
    recency_days,
    frequency_orders,
    monetary_revenue,
    last_purchase_date,
    'Win-back: personalized message with selective incentive' AS recommended_action
FROM scored
WHERE recency_quartile = 4
  AND monetary_quartile = 4
ORDER BY monetary_revenue DESC, recency_days DESC
LIMIT 500;
