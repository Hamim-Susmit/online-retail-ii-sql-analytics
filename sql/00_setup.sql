-- Create cleaned analytics view for Online Retail II
CREATE OR REPLACE VIEW retail_clean AS
SELECT
    invoice,
    invoice_date,
    CAST(invoice_date AS DATE) AS invoice_day,
    DATE_TRUNC('month', invoice_date) AS invoice_month,
    customer_id,
    stock_code,
    description,
    quantity,
    unit_price,
    country,
    quantity * unit_price AS revenue
FROM retail_transactions
WHERE customer_id IS NOT NULL
  AND quantity > 0
  AND unit_price > 0
  AND invoice NOT ILIKE 'C%';

-- Validation query
SELECT
    COUNT(*) AS row_count,
    MIN(invoice_date) AS min_invoice_date,
    MAX(invoice_date) AS max_invoice_date,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM retail_clean;
