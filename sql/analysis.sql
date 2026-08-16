-- Q1: Checking the date range and no. of business days covered in the data 
-- Finding: The data covers 463 business days from 2024-10-01 to 2026-08-06
SELECT min (record_date), max(record_date), COUNT(DISTINCT record_date) AS business_days
FROM cash_balance;

-- Q2: Finding the distinct account types in cash balance 
-- Finding: There are 4 types of accounts - opening balance, deposits, withdrawals and closing balance
SELECT DISTINCT account_type
FROM cash_balance;

-- Q3: For every business day, how much cash did the U.S. Treasury have at the end of that day?
SELECT record_date, CAST(open_today_bal AS REAL) AS closing_balance
FROM cash_balance
WHERE account_type LIKE '%Closing%'
  AND record_date <= '2026-07-31'
ORDER BY record_date DESC;

-- Q4: Top 10 highest and lowest closing balances 
-- Finding: The highest TGA closing balances were concentrated in April 2026, reaching about $1.04T on April 20. 
-- This may be driven by tax season, since April 15 is a significant deadline for paying federal individual income taxes, boosting cash inflows. 
-- Another peak occurred in late October 2025, reaching about $1.0T on October 30. 
-- This followed the rebuilding of the TGA after the debt ceiling was raised in July. 
-- The Oct–Nov government shutdown may have also contributed by temporarily reducing some government outflows while receipts and debt issuance continued. 
-- The lowest balances were concentrated between March and July 2025, reaching about $261B on June 12. 
-- During this period, the debt ceiling constrained new borrowing, requiring Treasury to rely more heavily on its existing cash balance.
SELECT record_date, CAST(open_today_bal AS REAL) AS closing_balance
FROM cash_balance
WHERE account_type LIKE '%Closing%'
	AND record_date <= '2026-07-31'
ORDER BY closing_balance DESC
LIMIT 10;

SELECT record_date, CAST(open_today_bal AS REAL) AS closing_balance
FROM cash_balance
WHERE account_type LIKE '%Closing%'
	AND record_date <= '2026-07-31'
ORDER BY closing_balance ASC
LIMIT 10;

-- Q5: Over the entire period, did Treasury receive more cash than it paid out, and by how much?
-- Finding: Treasury received about $70.02T in deposits and paid out about $70.03T in withdrawals, resulting in a net cash outflow of approximately $93.3B.
-- CONSTRAINT: only detail rows used ("Type of Account" = TGA). The "Total Deposits/Withdrawals" rows are Treasury's daily sums of the same rows including them would double-count.
SELECT "Transaction Type",
       SUM(CAST("Transactions Today" AS REAL)) AS total_millions
FROM deposits_withdrawals
WHERE "Type of Account" = 'Treasury General Account (TGA)'
GROUP BY  "Transaction Type";

-- Q6: Top 10 deposit and withdrawal categories 
-- Findings: Deposits were dominated by public debt issuance ($58.4T), showing that borrowing
-- is the largest source of cash flowing into the TGA. Among non-debt inflows,
-- withheld individual/FICA taxes were the largest at about $6.4T.
-- Withdrawals were dominated by public debt redemptions ($55.3T), reflecting
-- repayment of maturing Treasury securities. Major non-debt outflows included
-- Social Security benefits ($2.6T), Medicaid ($1.3T), interest on Treasury
-- securities ($1.2T), Medicare-related payments, and defense spending.
SELECT "Transaction Category",
       SUM(CAST("Transactions Today" AS REAL)) AS total_millions
FROM deposits_withdrawals
WHERE "Type of Account" = 'Treasury General Account (TGA)'
  AND "Transaction Type" = 'Deposits'
GROUP BY "Transaction Category"
ORDER BY total_millions DESC
LIMIT 10;

SELECT "Transaction Category",
       SUM(CAST("Transactions Today" AS REAL)) AS total_millions
FROM deposits_withdrawals
WHERE "Type of Account" = 'Treasury General Account (TGA)'
  AND "Transaction Type" = 'Withdrawals'
GROUP BY "Transaction Category"
ORDER BY total_millions DESC
LIMIT 10;

-- Q7: Monthly net cash flow
WITH monthly_flows AS (
    SELECT
        strftime('%Y-%m', "Record Date") AS month,
        SUM(CASE
            WHEN "Transaction Type" = 'Deposits'
            THEN CAST("Transactions Today" AS REAL)
            ELSE 0
        END) AS deposits,
        SUM(CASE
            WHEN "Transaction Type" = 'Withdrawals'
            THEN CAST("Transactions Today" AS REAL)
            ELSE 0
        END) AS withdrawals
    FROM deposits_withdrawals
    WHERE "Type of Account" = 'Treasury General Account (TGA)'
    GROUP BY month
)
SELECT
    month,
    deposits,
    withdrawals,
    deposits - withdrawals AS net_cash_flow
FROM monthly_flows
ORDER BY month;

-- Q8:Seasonality in individual income tax receipts
-- Findings: Individual tax receipts show a clear, repeating seasonal pattern.
-- April was the strongest month in both years, reaching $763B in 2025 and $797B in 2026, roughly 2.5x a typical month. 
-- Smaller peaks appear around quarterly estimated-tax deadlines in January, June, and September.
-- Receipts grew ~5-7% YoY
SELECT strftime('%Y-%m', "Record Date") AS month,
    SUM(CAST("Transactions Today" AS REAL)) AS total_amount
FROM deposits_withdrawals
WHERE "Type of Account" = 'Treasury General Account (TGA)'
  AND "Transaction Type" = 'Deposits'
  AND (
      "Transaction Category" = 'Taxes - Withheld Individual/FICA'
      OR "Transaction Category" = 'Taxes - Non Withheld Ind/SECA Electronic'
      OR "Transaction Category" = 'Taxes - Non Withheld Ind/SECA Other'
  )
GROUP BY month;

-- Q9: 30-business-day moving average and day-over-day change in TGA closing balance
WITH daily_balance AS (
    SELECT
        record_date,
        CAST(open_today_bal AS REAL) AS closing_bal
    FROM cash_balance
    WHERE account_type LIKE '%Closing%' AND record_date <= '2026-07-31'
)
SELECT record_date, closing_bal,
    ROUND(AVG(closing_bal) OVER (
        ORDER BY record_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ), 0) AS moving_avg_30,
    closing_bal - LAG(closing_bal) OVER (
        ORDER BY record_date
    ) AS daily_change
FROM daily_balance
ORDER BY record_date;

-- Q10: What were the 5 largest single-day drops?  If you have to set a minimum cash buffer, what would the 5 worst days in the data suggest?
-- Finding: The largest single-day TGA decline was $121.4B on July 31, 2026.
-- All five largest drops exceeded $100B, showing that Treasury's cash position can decline significantly within a single business day. 
-- Based on these historical observations, a minimum liquidity buffer should account for at least $120B of potential daily cash movement, with additional headroom for unexpected outflows.
WITH daily_balance AS (
    SELECT record_date,
        CAST(open_today_bal AS REAL) AS closing_bal
    FROM cash_balance
    WHERE account_type LIKE '%Closing%'
    AND record_date <= '2026-07-31'
),
daily_changes AS (
    SELECT record_date, closing_bal,
        closing_bal - LAG(closing_bal) OVER (
            ORDER BY record_date
        ) AS daily_change
    FROM daily_balance
)
SELECT *
FROM daily_changes
WHERE daily_change IS NOT NULL
ORDER BY daily_change ASC
LIMIT 5;

-- V1: daily balance, 30 day moving average, daily change
CREATE VIEW daily_balances AS
WITH daily_balance AS (
    SELECT record_date,
           CAST(open_today_bal AS REAL) AS closing_balance
    FROM cash_balance
    WHERE account_type LIKE '%Closing%'
      AND record_date <= '2026-07-31'
)
SELECT record_date, closing_balance,
       ROUND(AVG(closing_balance) OVER (ORDER BY record_date
             ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 0) AS moving_average_30,
       closing_balance - LAG(closing_balance) OVER (ORDER BY record_date) AS daily_change
FROM daily_balance;

-- V2: monthly flows 
CREATE VIEW monthly_flows AS
SELECT strftime('%Y-%m', "Record Date") AS month,
       SUM(CASE WHEN "Transaction Type" = 'Deposits'
                THEN CAST("Transactions Today" AS REAL) ELSE 0 END) AS deposits,
       SUM(CASE WHEN "Transaction Type" = 'Withdrawals'
                THEN CAST("Transactions Today" AS REAL) ELSE 0 END) AS withdrawals,
       SUM(CASE WHEN "Transaction Type" = 'Deposits'
                THEN CAST("Transactions Today" AS REAL)
                ELSE -CAST("Transactions Today" AS REAL) END) AS net_cash_flow
FROM deposits_withdrawals
WHERE "Type of Account" = 'Treasury General Account (TGA)'
GROUP BY month;

-- V3: category totals, all categories both types 
CREATE VIEW category_totals AS
SELECT "Transaction Category" AS category,
       "Transaction Type" AS txn_type,
       SUM(CAST("Transactions Today" AS REAL)) AS total_amount
FROM deposits_withdrawals
WHERE "Type of Account" = 'Treasury General Account (TGA)'
GROUP BY category, txn_type;

SELECT * FROM category_totals;