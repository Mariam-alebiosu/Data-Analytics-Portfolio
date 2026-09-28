/*
============================================================
COMMERCIAL PERFORMANCE SQL ANALYSIS
Dataset: UCI Online Retail

============================================================
*/

-- 1. DATA QUALITY PROFILE
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT InvoiceNo) AS unique_invoices,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    COUNT(DISTINCT Country) AS countries,
    MIN(InvoiceDate) AS first_transaction,
    MAX(InvoiceDate) AS last_transaction,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS missing_customer_ids,
    SUM(CASE WHEN Description IS NULL THEN 1 ELSE 0 END) AS missing_descriptions
FROM ONLINE_RETAIL;


-- 2. CLEAN COMPLETED SALES VIEW
CREATE OR REPLACE VIEW COMPLETED_SALES AS
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    Quantity * UnitPrice AS Revenue
FROM ONLINE_RETAIL
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0;


-- 3. EXECUTIVE COMMERCIAL KPIs
SELECT
    ROUND(SUM(Revenue), 2) AS total_revenue,
    COUNT(DISTINCT InvoiceNo) AS completed_orders,
    COUNT(DISTINCT CustomerID) AS identified_customers,
    ROUND(
        SUM(Revenue) / NULLIF(COUNT(DISTINCT InvoiceNo), 0),
        2
    ) AS average_order_value
FROM COMPLETED_SALES;


-- 4. MONTHLY REVENUE PERFORMANCE
SELECT
    DATE_TRUNC('MONTH', InvoiceDate) AS month,
    ROUND(SUM(Revenue), 2) AS revenue,
    COUNT(DISTINCT InvoiceNo) AS orders,
    ROUND(
        SUM(Revenue) / NULLIF(COUNT(DISTINCT InvoiceNo), 0),
        2
    ) AS average_order_value
FROM COMPLETED_SALES
GROUP BY 1
ORDER BY 1;


-- 5. MONTH-ON-MONTH REVENUE CHANGE
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('MONTH', InvoiceDate) AS month,
        SUM(Revenue) AS revenue
    FROM COMPLETED_SALES
    GROUP BY 1
),
monthly_comparison AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        100 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS month_on_month_change_pct
FROM monthly_comparison
ORDER BY month;


-- 6. COUNTRY PERFORMANCE
SELECT
    Country,
    ROUND(SUM(Revenue), 2) AS revenue,
    COUNT(DISTINCT InvoiceNo) AS orders,
    COUNT(DISTINCT CustomerID) AS customers,
    ROUND(
        SUM(Revenue) / NULLIF(COUNT(DISTINCT InvoiceNo), 0),
        2
    ) AS average_order_value
FROM COMPLETED_SALES
GROUP BY Country
ORDER BY revenue DESC;


-- 7. COUNTRY REVENUE SHARE
WITH country_revenue AS (
    SELECT
        Country,
        SUM(Revenue) AS revenue
    FROM COMPLETED_SALES
    GROUP BY Country
)
SELECT
    Country,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        100 * revenue / SUM(revenue) OVER (),
        2
    ) AS revenue_share_pct
FROM country_revenue
ORDER BY revenue DESC;


-- 8. TOP PRODUCTS BY REVENUE
SELECT
    StockCode,
    Description,
    SUM(Quantity) AS units_sold,
    ROUND(SUM(Revenue), 2) AS revenue
FROM COMPLETED_SALES
GROUP BY StockCode, Description
ORDER BY revenue DESC
LIMIT 20;


-- 9. TOP CUSTOMERS BY REVENUE
SELECT
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS orders,
    ROUND(SUM(Revenue), 2) AS revenue,
    ROUND(
        SUM(Revenue) / NULLIF(COUNT(DISTINCT InvoiceNo), 0),
        2
    ) AS average_order_value
FROM COMPLETED_SALES
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY revenue DESC
LIMIT 20;


-- 10. REPEAT CUSTOMER RATE
WITH customer_orders AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count
    FROM COMPLETED_SALES
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT
    COUNT(*) AS customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_rate_pct
FROM customer_orders;


-- 11. CUSTOMER VALUE SEGMENTATION
WITH customer_summary AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS orders,
        SUM(Revenue) AS revenue
    FROM COMPLETED_SALES
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),
customer_segments AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY revenue DESC) AS revenue_quartile
    FROM customer_summary
)
SELECT
    CASE revenue_quartile
        WHEN 1 THEN 'High Value'
        WHEN 2 THEN 'Upper Mid Value'
        WHEN 3 THEN 'Lower Mid Value'
        ELSE 'Lower Value'
    END AS customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(AVG(revenue), 2) AS average_customer_revenue
FROM customer_segments
GROUP BY revenue_quartile
ORDER BY revenue_quartile;


-- 12. CANCELLATION ANALYSIS
SELECT
    COUNT(DISTINCT InvoiceNo) AS cancelled_invoices,
    ROUND(SUM(ABS(Quantity) * UnitPrice), 2) AS estimated_cancellation_value
FROM ONLINE_RETAIL
WHERE InvoiceNo LIKE 'C%'
  AND UnitPrice > 0;


-- 13. CANCELLATION INVOICE RATE
SELECT
    COUNT(DISTINCT CASE
        WHEN InvoiceNo LIKE 'C%' THEN InvoiceNo
    END) AS cancelled_invoices,
    COUNT(DISTINCT InvoiceNo) AS total_invoice_identifiers,
    ROUND(
        100.0 *
        COUNT(DISTINCT CASE WHEN InvoiceNo LIKE 'C%' THEN InvoiceNo END)
        / NULLIF(COUNT(DISTINCT InvoiceNo), 0),
        2
    ) AS cancellation_invoice_rate_pct
FROM ONLINE_RETAIL;


-- 14. MONTHLY CANCELLATION VALUE
SELECT
    DATE_TRUNC('MONTH', InvoiceDate) AS month,
    COUNT(DISTINCT InvoiceNo) AS cancelled_invoices,
    ROUND(SUM(ABS(Quantity) * UnitPrice), 2) AS cancellation_value
FROM ONLINE_RETAIL
WHERE InvoiceNo LIKE 'C%'
  AND UnitPrice > 0
GROUP BY 1
ORDER BY 1;
