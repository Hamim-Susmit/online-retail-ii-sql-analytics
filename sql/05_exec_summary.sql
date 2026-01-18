-- =============================================================
-- Executive Summary Queries
-- =============================================================

-- ===== Query 1: Monthly KPIs =====
SELECT
    invoice_month AS month,
    COUNT(DISTINCT customer_id) AS monthly_active_customers,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT invoice) AS orders,
    SUM(revenue) / NULLIF(COUNT(DISTINCT invoice), 0) AS aov
FROM retail_clean
GROUP BY invoice_month
ORDER BY invoice_month;

-- ===== Query 2: Top 10 countries by revenue share =====
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

-- ===== Query 3: Top 10 products by revenue share =====
WITH product_revenue AS (
    SELECT
        stock_code,
        MAX(description) AS description,
        SUM(revenue) AS total_revenue
    FROM retail_clean
    WHERE COALESCE(TRIM(description), '') <> ''
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

-- ===== Query 4: Month+1 retention summary =====
WITH customer_months AS (
    SELECT DISTINCT
        customer_id,
        invoice_month
    FROM retail_clean
), customer_cohorts AS (
    SELECT
        customer_id,
        MIN(invoice_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_id
), cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
), cohort_activity AS (
    SELECT
        cm.customer_id,
        cc.cohort_month,
        cm.invoice_month AS activity_month,
        (EXTRACT(YEAR FROM cm.invoice_month) - EXTRACT(YEAR FROM cc.cohort_month)) * 12
        + (EXTRACT(MONTH FROM cm.invoice_month) - EXTRACT(MONTH FROM cc.cohort_month))
            AS months_since
    FROM customer_months cm
    INNER JOIN customer_cohorts cc
        ON cm.customer_id = cc.customer_id
    WHERE (EXTRACT(YEAR FROM cm.invoice_month) - EXTRACT(YEAR FROM cc.cohort_month)) * 12
        + (EXTRACT(MONTH FROM cm.invoice_month) - EXTRACT(MONTH FROM cc.cohort_month))
            >= 0
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

-- ===== Query 5: Campaign targeting table (At Risk High-Value) =====
-- Business rationale: high-value customers who have gone quiet deliver the highest ROI
-- for win-back campaigns because their past spend is strong but recency is weak.
WITH as_of_date AS (
    SELECT
        MAX(invoice_date::date) AS as_of_date
    FROM retail_clean
), customer_metrics AS (
    SELECT
        rc.customer_id,
        MIN(rc.invoice_date::date) AS first_purchase_date,
        MAX(rc.invoice_date::date) AS last_purchase_date,
        COUNT(DISTINCT rc.invoice) AS frequency_orders,
        SUM(rc.revenue) AS monetary_revenue
    FROM retail_clean rc
    GROUP BY rc.customer_id
), scored AS (
    SELECT
        cm.customer_id,
        cm.first_purchase_date,
        cm.last_purchase_date,
        (aod.as_of_date - cm.last_purchase_date)::int AS recency_days,
        cm.frequency_orders,
        cm.monetary_revenue,
        NTILE(4) OVER (ORDER BY (aod.as_of_date - cm.last_purchase_date) DESC) AS recency_quartile,
        NTILE(4) OVER (ORDER BY cm.monetary_revenue ASC) AS monetary_quartile
    FROM customer_metrics cm
    CROSS JOIN as_of_date aod
)
SELECT
    customer_id,
    recency_days,
    frequency_orders,
    monetary_revenue,
    first_purchase_date,
    last_purchase_date,
    'Win-back: personalized message with selective incentive' AS recommended_action
FROM scored
WHERE recency_quartile = 4
  AND monetary_quartile = 4
ORDER BY monetary_revenue DESC, recency_days DESC
LIMIT 500;
