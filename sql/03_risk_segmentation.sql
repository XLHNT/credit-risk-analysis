--3.
-- Credit utilization categories and risk analysis

    SELECT 
    CASE 
        WHEN RevolvingUtilizationOfUnsecuredLines IS NULL THEN '0. Missing Data'
        WHEN RevolvingUtilizationOfUnsecuredLines = 0 THEN '1. 0%: No Utilization'
        WHEN RevolvingUtilizationOfUnsecuredLines <= 0.30 THEN '2. 1-30%: Low Utilization'
        WHEN RevolvingUtilizationOfUnsecuredLines <= 0.70 THEN '3. 31-70%: Medium Utilization'
        WHEN RevolvingUtilizationOfUnsecuredLines <= 1.00 THEN '4. 71-100%: High Utilization'
        ELSE '5. Over 100%: Over-Limit'
    END AS utilization_category,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_customers,
    SUM(SeriousDlqin2yrs) AS total_defaulters,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct,
    ROUND(AVG(RevolvingUtilizationOfUnsecuredLines), 3) AS avg_utilization_in_category
FROM [Credit Risk Analysis].dbo.[training$]
GROUP BY 
    CASE 
        WHEN RevolvingUtilizationOfUnsecuredLines IS NULL THEN '0. Missing Data'
        WHEN RevolvingUtilizationOfUnsecuredLines = 0 THEN '1. 0%: No Utilization'
        WHEN RevolvingUtilizationOfUnsecuredLines <= 0.30 THEN '2. 1-30%: Low Utilization'
        WHEN RevolvingUtilizationOfUnsecuredLines <= 0.70 THEN '3. 31-70%: Medium Utilization'
        WHEN RevolvingUtilizationOfUnsecuredLines <= 1.00 THEN '4. 71-100%: High Utilization'
        ELSE '5. Over 100%: Over-Limit'
    END
ORDER BY 
    CASE 
        WHEN RevolvingUtilizationOfUnsecuredLines IS NULL THEN '0. Missing Data'
        WHEN RevolvingUtilizationOfUnsecuredLines = 0 THEN '1. 0%: No Utilization'
        WHEN RevolvingUtilizationOfUnsecuredLines <= 0.30 THEN '2. 1-30%: Low Utilization'
        WHEN RevolvingUtilizationOfUnsecuredLines <= 0.70 THEN '3. 31-70%: Medium Utilization'
        WHEN RevolvingUtilizationOfUnsecuredLines <= 1.00 THEN '4. 71-100%: High Utilization'
        ELSE '5. Over 100%: Over-Limit'
    END;





 --4.
 -- Overall delinquency rate

SELECT 
    COUNT(*) AS total_customers,
    SUM(SeriousDlqin2yrs) AS total_defaulters,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS overall_default_rate_pct
FROM [Credit Risk Analysis].dbo.[training$];

-- Default rate by age and income brackets
SELECT 
    CASE 
        WHEN age < 30 THEN '18-29'
        WHEN age < 40 THEN '30-39'
        WHEN age < 50 THEN '40-49'
        WHEN age < 60 THEN '50-59'
        ELSE '60+'
    END AS age_bracket,
    CASE 
        WHEN MonthlyIncome IS NULL THEN 'Income Unknown'
        WHEN MonthlyIncome < 3000 THEN 'Under $3k'
        WHEN MonthlyIncome < 5000 THEN '$3k-$5k'
        WHEN MonthlyIncome < 8000 THEN '$5k-$8k'
        ELSE '$8k+'
    END AS income_bracket,
    COUNT(*) AS customers,
    SUM(SeriousDlqin2yrs) AS defaulters,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct
FROM [Credit Risk Analysis].dbo.[training$]
GROUP BY 
    CASE 
        WHEN age < 30 THEN '18-29'
        WHEN age < 40 THEN '30-39'
        WHEN age < 50 THEN '40-49'
        WHEN age < 60 THEN '50-59'
        ELSE '60+'
    END,
    CASE 
        WHEN MonthlyIncome IS NULL THEN 'Income Unknown'
        WHEN MonthlyIncome < 3000 THEN 'Under $3k'
        WHEN MonthlyIncome < 5000 THEN '$3k-$5k'
        WHEN MonthlyIncome < 8000 THEN '$5k-$8k'
        ELSE '$8k+'
    END
HAVING COUNT(*) > 100  -- Only show segments with meaningful sample size
ORDER BY default_rate_pct DESC;





-- Q5
-- Which customers exhibit multiple risk indicators that warrant immediate attention? Create a comprehensive risk scoring model using five key indicators.

-- Part A: Individual customer risk scores

WITH risk_indicators AS (
    SELECT 
        Id,
        age,
        MonthlyIncome,
        SeriousDlqin2yrs,
        
        CASE WHEN RevolvingUtilizationOfUnsecuredLines > 0.80 THEN 1 ELSE 0 END AS high_utilization_flag,
        CASE WHEN NumberOfTimes90DaysLate > 0 THEN 1 ELSE 0 END AS severe_delinquency_flag,
        CASE WHEN DebtRatio > 0.5 THEN 1 ELSE 0 END AS high_debt_ratio_flag,
        CASE WHEN [NumberOfTime30-59DaysPastDueNotWorse] > 2 THEN 1 ELSE 0 END AS frequent_late_payments_flag,
        CASE WHEN MonthlyIncome < 2000 OR MonthlyIncome IS NULL THEN 1 ELSE 0 END AS low_income_flag
    FROM [Credit Risk Analysis].dbo.[training$]
)
SELECT TOP 100
    Id,
    age,
    MonthlyIncome,
    (high_utilization_flag + severe_delinquency_flag + high_debt_ratio_flag + 
     frequent_late_payments_flag + low_income_flag) AS total_risk_indicators,
    high_utilization_flag,
    severe_delinquency_flag,
    high_debt_ratio_flag,
    frequent_late_payments_flag,
    low_income_flag,
    SeriousDlqin2yrs AS actually_defaulted
FROM risk_indicators
WHERE (high_utilization_flag + severe_delinquency_flag + high_debt_ratio_flag + 
       frequent_late_payments_flag + low_income_flag) >= 3
ORDER BY total_risk_indicators DESC, SeriousDlqin2yrs DESC;

-- Part B: Summary statistics
SELECT 
    total_risk_indicators,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_portfolio,
    SUM(SeriousDlqin2yrs) AS actual_defaulters,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct
FROM (
    SELECT 
        Id,
        SeriousDlqin2yrs,
        (CASE WHEN RevolvingUtilizationOfUnsecuredLines > 0.80 THEN 1 ELSE 0 END +
         CASE WHEN NumberOfTimes90DaysLate > 0 THEN 1 ELSE 0 END +
         CASE WHEN DebtRatio > 0.5 THEN 1 ELSE 0 END +
         CASE WHEN [NumberOfTime30-59DaysPastDueNotWorse] > 2 THEN 1 ELSE 0 END +
         CASE WHEN MonthlyIncome < 2000 OR MonthlyIncome IS NULL THEN 1 ELSE 0 END
        ) AS total_risk_indicators
    FROM [Credit Risk Analysis].dbo.[training$]
) risk_summary
GROUP BY total_risk_indicators
ORDER BY total_risk_indicators;



--10.
-- Risk ranking within age cohorts using window functions

WITH risk_score_calculation AS (
    SELECT 
        Id,
        age,
        MonthlyIncome,
        SeriousDlqin2yrs,
        
        CASE 
            WHEN age < 30 THEN '18-29'
            WHEN age < 40 THEN '30-39'
            WHEN age < 50 THEN '40-49'
            WHEN age < 60 THEN '50-59'
            ELSE '60+'
        END AS age_group,
        
        (CASE WHEN RevolvingUtilizationOfUnsecuredLines > 0.80 THEN 20 ELSE 0 END +
         CASE WHEN NumberOfTimes90DaysLate > 0 THEN 30 ELSE 0 END +
         CASE WHEN DebtRatio > 0.50 THEN 15 ELSE 0 END +
         CASE WHEN [NumberOfTime30-59DaysPastDueNotWorse] > 2 THEN 10 ELSE 0 END +
         CASE WHEN MonthlyIncome < 2000 OR MonthlyIncome IS NULL THEN 15 ELSE 0 END +
         (NumberOfTimes90DaysLate * 5) +
         ([NumberOfTime30-59DaysPastDueNotWorse] * 2)
        ) AS composite_risk_score
    FROM [Credit Risk Analysis].dbo.[training$]
    WHERE age IS NOT NULL
),
ranked_customers AS (
    SELECT 
        Id,
        age,
        age_group,
        MonthlyIncome,
        composite_risk_score,
        SeriousDlqin2yrs,
        ROW_NUMBER() OVER (PARTITION BY age_group ORDER BY composite_risk_score DESC) AS risk_rank_in_group,
        NTILE(10) OVER (PARTITION BY age_group ORDER BY composite_risk_score DESC) AS risk_decile,
        COUNT(*) OVER (PARTITION BY age_group) AS total_in_group
    FROM risk_score_calculation
)
SELECT 
    Id,
    age,
    age_group,
    MonthlyIncome,
    composite_risk_score,
    risk_rank_in_group,
    risk_decile,
    SeriousDlqin2yrs AS actually_defaulted,
    ROUND(100.0 * risk_rank_in_group / total_in_group, 2) AS percentile_rank
FROM ranked_customers
WHERE risk_decile = 1
ORDER BY age_group, composite_risk_score DESC;


