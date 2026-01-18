-- =============================================================
-- Cohort Retention Analysis
-- Logic:
--   - Cohort month = first purchase month per customer
--   - months_since = month difference between activity and cohort
--   - Use distinct customer-month activity for performance
--   - Guard against negative months_since from bad data
-- =============================================================

-- Query 1: Cohort retention counts by months since first purchase
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
)
SELECT
    cohort_month,
    months_since,
    COUNT(DISTINCT customer_id) AS retained_customers
FROM cohort_activity
GROUP BY cohort_month, months_since
ORDER BY cohort_month, months_since;

-- Query 2: Cohort retention rates
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
    r.cohort_month,
    r.months_since,
    r.retained_customers,
    cs.cohort_size,
    r.retained_customers::numeric / NULLIF(cs.cohort_size, 0) AS retention_rate
FROM retained r
INNER JOIN cohort_sizes cs
    ON r.cohort_month = cs.cohort_month
ORDER BY r.cohort_month, r.months_since;

-- Query 3: Cohort retention grid (months 0-6)
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
), retention_rates AS (
    SELECT
        r.cohort_month,
        r.months_since,
        r.retained_customers::numeric / NULLIF(cs.cohort_size, 0) AS retention_rate
    FROM retained r
    INNER JOIN cohort_sizes cs
        ON r.cohort_month = cs.cohort_month
)
SELECT
    cohort_month,
    COALESCE(MAX(CASE WHEN months_since = 0 THEN retention_rate END), 0.0) AS m0,
    COALESCE(MAX(CASE WHEN months_since = 1 THEN retention_rate END), 0.0) AS m1,
    COALESCE(MAX(CASE WHEN months_since = 2 THEN retention_rate END), 0.0) AS m2,
    COALESCE(MAX(CASE WHEN months_since = 3 THEN retention_rate END), 0.0) AS m3,
    COALESCE(MAX(CASE WHEN months_since = 4 THEN retention_rate END), 0.0) AS m4,
    COALESCE(MAX(CASE WHEN months_since = 5 THEN retention_rate END), 0.0) AS m5,
    COALESCE(MAX(CASE WHEN months_since = 6 THEN retention_rate END), 0.0) AS m6
FROM retention_rates
GROUP BY cohort_month
ORDER BY cohort_month;
