U.S. Treasury Cash & Liquidity Analytics

Executive Summary
Using SQL and Tableau, I analyzed 22 months of daily U.S. Treasury cash data — 463 business days of balances and ~83,000 category-level transactions to understand how the government's operating cash account (the TGA) behaves: what drives it, how volatile it is, and how much cash it should hold. After finding that the balance swung 4x in the period and that the worst outflow days are concentrated and predictable, I recommend:

A minimum cash buffer of ~$200B (about one week of outflows), based on the worst 5-day drawdown observed
Planning liquidity around the payment calendar — the largest single-day outflows all fall on month-start payment dates
Treating tax-deadline months (Apr, Jun, Jan, Sep) as structural inflow peaks, since the pattern repeated across both years

▶ View the live interactive dashboard

Business Problem
The Treasury General Account is the U.S. government's checking account at the Federal Reserve. Like any corporate treasury, whoever manages it needs answers to the same questions: What is our cash position and how has it been trending? What actually drives the inflows and outflows? How much of the movement is predictable versus random? And given the worst days on record, how much cash is enough? This project answers those questions with public data — the same liquidity-management problem every treasury desk faces, at the largest scale there is.

Methodology
Pulled two datasets from the official Daily Treasury Statement (U.S. Treasury Fiscal Data): daily operating cash balances and category-level deposits/withdrawals, Oct 2024 – Jul 2026.
Loaded both into SQLite and validated the data before analyzing it: verified the daily accounting identity (opening + deposits − withdrawals = closing) across all 463 days (ties out within ±$1M rounding), confirmed each day's open matches the prior close, and reconciled category detail against Treasury's own daily totals.
Wrote the analysis in SQL — aggregations, CASE pivots, CTEs, and window functions for the 30-day moving average and day-over-day changes — and packaged the outputs as three reusable views (sql/analysis.sql, findings documented as comments on each query).
Built a four-chart Tableau dashboard fed only by those views, so all logic lives in SQL and Tableau is purely the presentation layer (tableau/).

Skills
SQL: CTEs, window functions (moving averages, LAG), CASE pivots, aggregate functions, views, data validation and reconciliation
Tableau: dual-axis charts, calculated fields, top-N and exclusion filters, KPI design, dashboard layout, publishing to Tableau Public
Analysis: data quality auditing, time-series and seasonality analysis, volatility measurement, translating findings into a business recommendation

Results & Business Recommendation
The cash balance ranged from $261B (June 2025, when the debt ceiling constrained borrowing and Treasury ran down its cash) to $1,038B (April 2026, right after the tax deadline) — a 4x swing in 22 months. Most daily movement is debt being rolled over: issuance was 83% of all deposits and redemptions 79% of withdrawals, with net borrowing of $3.1T financing the deficit. On the operational side, withheld payroll taxes were the largest inflow ($6.4T), while Social Security ($2.6T), Medicaid and Medicare ($3.2T), and interest on the debt ($1.2T) led the outflows. April tax receipts ran ~2.5x a normal month in both years, and all five of the worst single-day drops ($106–121B) landed on month-start payment dates, with the worst week draining ~$190B.

The recommendation: hold a minimum buffer of roughly $200B — about one week of outflows. That figure comes directly from the observed worst-case drawdowns, and it matches Treasury's own stated cash policy. The June 2025 low of $261B shows how close the account came to that floor when new borrowing was constrained.

Assumptions: amounts in $ millions · business days only · window cut at Jul 31, 2026 (last complete month) · closing balance read from open_today_bal where close_today_bal is null (current data-format quirk) · flow analysis uses TGA detail rows only, as Treasury's daily "Total" rows restate the same money.

Next Steps
Automate the data pull from the Fiscal Data REST API so the dashboard refreshes on a schedule
Build a 30-day cash forecast: drift baseline first, then layer in the known payment calendar (tax deadlines, benefit payment dates, auction settlements)
Separate operational from financing flows using the debt transaction detail (DTS Table III)

How to Reach Me
Kavya Gupta LinkedIn · guptakavya340@gmail.com · +1 9193581457

