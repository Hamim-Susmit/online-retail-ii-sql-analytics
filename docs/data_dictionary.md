# Data Dictionary — `retail_clean`

## Purpose
The `retail_clean` view standardizes Online Retail II transactions for analytics and removes invalid or cancelled records.

## Columns
| Column | Type | Description |
| --- | --- | --- |
| invoice | text | Invoice identifier from the source system. |
| invoice_date | timestamp/date | Original invoice timestamp. |
| invoice_day | date | `CAST(invoice_date AS DATE)` to support daily reporting. |
| invoice_month | timestamp | `DATE_TRUNC('month', invoice_date)` to support monthly reporting. |
| customer_id | text/integer | Unique customer identifier. |
| stock_code | text | Product stock code (SKU). |
| description | text | Product description. |
| quantity | numeric | Units purchased for the line item. |
| unit_price | numeric | Unit price of the item. |
| country | text | Customer country. |
| revenue | numeric | `quantity * unit_price` per line item. |

## Filtering & Standardization Rules
- Exclude rows where `customer_id` is NULL.
- Exclude rows where `quantity <= 0` or `unit_price <= 0`.
- Exclude cancellations/returns where `invoice` starts with `C`.
- Compute `revenue` as `quantity * unit_price`.
- Normalize invoice date into `invoice_day` and `invoice_month`.

## Notes
- All downstream analytics queries read **only** from `retail_clean`.
- The view is designed for **PostgreSQL/Supabase** compatibility.
