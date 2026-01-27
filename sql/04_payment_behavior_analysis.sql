-- Q11: PAYMENT RELIABILITY SCORING SYSTEM
-- How can we create a weighted payment reliability score that reflects the severity of different late payment patterns?

-- Part A: Individual customer scores with rankings

WITH payment_scoring AS (
    SELECT 
        Id,
        age,
        MonthlyIncome,
        SeriousDlqin2yrs,
        
        ([NumberOfTime30-59DaysPastDueNotWorse] * 1 +
         [NumberOfTime60-89DaysPastDueNotWorse] * 2 +
         NumberOfTimes90DaysLate * 3) AS weighted_late_payment_score,
        
        [NumberOfTime30-59DaysPastDueNotWorse],
        [NumberOfTime60-89DaysPastDueNotWorse],
        NumberOfTimes90DaysLate
    FROM [Credit Risk Analysis].dbo.[training$]
),
scored_and_ranked AS (
    SELECT 
        Id,
        age,
        MonthlyIncome,
        weighted_late_payment_score,
        [NumberOfTime30-59DaysPastDueNotWorse],
        [NumberOfTime60-89DaysPastDueNotWorse],
        NumberOfTimes90DaysLate,
        SeriousDlqin2yrs,
        
        NTILE(100) OVER (ORDER BY weighted_late_payment_score) AS payment_score_percentile,
        RANK() OVER (ORDER BY weighted_late_payment_score DESC) AS payment_risk_rank
    FROM payment_scoring
)
SELECT TOP 500
    Id,
    age,
    MonthlyIncome,
    weighted_late_payment_score,
    payment_score_percentile,
    payment_risk_rank,
    [NumberOfTime30-59DaysPastDueNotWorse] AS late_30_59_days,
    [NumberOfTime60-89DaysPastDueNotWorse] AS late_60_89_days,
    NumberOfTimes90DaysLate AS late_90_plus_days,
    SeriousDlqin2yrs AS actually_defaulted
FROM scored_and_ranked
WHERE weighted_late_payment_score > 0
ORDER BY weighted_late_payment_score DESC;

-- Part B: Distribution summary (SEPARATE QUERY)
WITH payment_scoring AS (
    SELECT 
        Id,
        age,
        MonthlyIncome,
        SeriousDlqin2yrs,
        
        ([NumberOfTime30-59DaysPastDueNotWorse] * 1 +
         [NumberOfTime60-89DaysPastDueNotWorse] * 2 +
         NumberOfTimes90DaysLate * 3) AS weighted_late_payment_score,
        
        [NumberOfTime30-59DaysPastDueNotWorse],
        [NumberOfTime60-89DaysPastDueNotWorse],
        NumberOfTimes90DaysLate
    FROM [Credit Risk Analysis].dbo.[training$]
),
scored_and_ranked AS (
    SELECT 
        Id,
        age,
        MonthlyIncome,
        weighted_late_payment_score,
        [NumberOfTime30-59DaysPastDueNotWorse],
        [NumberOfTime60-89DaysPastDueNotWorse],
        NumberOfTimes90DaysLate,
        SeriousDlqin2yrs,
        
        NTILE(100) OVER (ORDER BY weighted_late_payment_score) AS payment_score_percentile,
        RANK() OVER (ORDER BY weighted_late_payment_score DESC) AS payment_risk_rank
    FROM payment_scoring
)
SELECT 
    CASE 
        WHEN payment_score_percentile <= 25 THEN '1. Bottom 25% (Best Payment History)'
        WHEN payment_score_percentile <= 50 THEN '2. 26-50% Percentile'
        WHEN payment_score_percentile <= 75 THEN '3. 51-75% Percentile'
        ELSE '4. Top 25% (Worst Payment History)'
    END AS payment_reliability_tier,
    COUNT(*) AS customers,
    ROUND(AVG(weighted_late_payment_score), 2) AS avg_weighted_score,
    SUM(SeriousDlqin2yrs) AS defaulters,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct
FROM scored_and_ranked
GROUP BY 
    CASE 
        WHEN payment_score_percentile <= 25 THEN '1. Bottom 25% (Best Payment History)'
        WHEN payment_score_percentile <= 50 THEN '2. 26-50% Percentile'
        WHEN payment_score_percentile <= 75 THEN '3. 51-75% Percentile'
        ELSE '4. Top 25% (Worst Payment History)'
    END
ORDER BY payment_reliability_tier;





-- Q12: CUMULATIVE DEBT BURDEN DISTRIBUTION
-- What is the cumulative distribution of debt ratios across our customer base? At what percentile thresholds should we set risk alerts?

WITH ordered_customers AS (
    SELECT 
        Id,
        DebtRatio,
        MonthlyIncome,
        SeriousDlqin2yrs,
        ROW_NUMBER() OVER (ORDER BY DebtRatio) AS position,
        COUNT(*) OVER () AS total_customers
    FROM [Credit Risk Analysis].dbo.[training$]
    WHERE DebtRatio IS NOT NULL
),
cumulative_distribution AS (
    SELECT 
        Id,
        DebtRatio,
        MonthlyIncome,
        SeriousDlqin2yrs,
        position,
        total_customers,
        ROUND(100.0 * position / total_customers, 2) AS cumulative_percentile,
        SUM(CASE WHEN SeriousDlqin2yrs = 1 THEN 1 ELSE 0 END) 
            OVER (ORDER BY DebtRatio ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_defaulters,
        SUM(1) OVER (ORDER BY DebtRatio ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customers
    FROM ordered_customers
)
SELECT 
    DebtRatio,
    cumulative_percentile,
    cumulative_customers,
    cumulative_defaulters,
    ROUND(100.0 * cumulative_defaulters / cumulative_customers, 2) AS cumulative_default_rate
FROM cumulative_distribution
WHERE position % 1000 = 0 OR cumulative_percentile IN (25, 50, 75, 90, 95, 99)
ORDER BY DebtRatio;

-- Key percentile thresholds
WITH percentile_calc AS (
    SELECT 
        DebtRatio,
        ROUND(100.0 * ROW_NUMBER() OVER (ORDER BY DebtRatio) / COUNT(*) OVER(), 2) AS cumulative_percentile
    FROM [Credit Risk Analysis].dbo.[training$]
    WHERE DebtRatio IS NOT NULL
)
SELECT '25th Percentile' AS threshold_name,
       ROUND(MAX(CASE WHEN cumulative_percentile <= 25 THEN DebtRatio END), 3) AS debt_ratio_threshold
FROM percentile_calc
UNION ALL
SELECT '50th Percentile', ROUND(MAX(CASE WHEN cumulative_percentile <= 50 THEN DebtRatio END), 3)
FROM percentile_calc
UNION ALL
SELECT '75th Percentile', ROUND(MAX(CASE WHEN cumulative_percentile <= 75 THEN DebtRatio END), 3)
FROM percentile_calc
UNION ALL
SELECT '90th Percentile', ROUND(MAX(CASE WHEN cumulative_percentile <= 90 THEN DebtRatio END), 3)
FROM percentile_calc;


