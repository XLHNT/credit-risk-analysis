--Q18: EXECUTIVE RISK DASHBOARD - OPTIMIZED COMPREHENSIVE QUERY
--Create a single, performance-optimized query that delivers all critical risk metrics for executive decision-making.

WITH portfolio_overview AS (
    SELECT 
        COUNT(*) AS total_customers,
        SUM(SeriousDlqin2yrs) AS total_defaulters,
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS overall_default_rate,
        ROUND(AVG(CAST(age AS FLOAT)), 1) AS avg_customer_age,
        ROUND(AVG(MonthlyIncome), 0) AS avg_monthly_income,
        ROUND(AVG(DebtRatio), 3) AS avg_debt_ratio,
        ROUND(AVG(RevolvingUtilizationOfUnsecuredLines), 3) AS avg_utilization_rate
    FROM [Credit Risk Analysis].dbo.[training$]
),
risk_segment_distribution AS (
    SELECT 
        CASE 
            WHEN (CASE WHEN RevolvingUtilizationOfUnsecuredLines > 0.80 THEN 1 ELSE 0 END +
                  CASE WHEN NumberOfTimes90DaysLate > 0 THEN 1 ELSE 0 END +
                  CASE WHEN DebtRatio > 0.5 THEN 1 ELSE 0 END +
                  CASE WHEN MonthlyIncome < 2000 OR MonthlyIncome IS NULL THEN 1 ELSE 0 END) >= 3 
            THEN '3. High Risk'
            WHEN (CASE WHEN RevolvingUtilizationOfUnsecuredLines > 0.80 THEN 1 ELSE 0 END +
                  CASE WHEN NumberOfTimes90DaysLate > 0 THEN 1 ELSE 0 END +
                  CASE WHEN DebtRatio > 0.5 THEN 1 ELSE 0 END +
                  CASE WHEN MonthlyIncome < 2000 OR MonthlyIncome IS NULL THEN 1 ELSE 0 END) = 2 
            THEN '2. Medium Risk'
            ELSE '1. Low Risk'
        END AS risk_category,
        COUNT(*) AS customer_count,
        SUM(SeriousDlqin2yrs) AS defaulters,
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate
    FROM [Credit Risk Analysis].dbo.[training$]
    GROUP BY 
        CASE 
            WHEN (CASE WHEN RevolvingUtilizationOfUnsecuredLines > 0.80 THEN 1 ELSE 0 END +
                  CASE WHEN NumberOfTimes90DaysLate > 0 THEN 1 ELSE 0 END +
                  CASE WHEN DebtRatio > 0.5 THEN 1 ELSE 0 END +
                  CASE WHEN MonthlyIncome < 2000 OR MonthlyIncome IS NULL THEN 1 ELSE 0 END) >= 3 
            THEN '3. High Risk'
            WHEN (CASE WHEN RevolvingUtilizationOfUnsecuredLines > 0.80 THEN 1 ELSE 0 END +
                  CASE WHEN NumberOfTimes90DaysLate > 0 THEN 1 ELSE 0 END +
                  CASE WHEN DebtRatio > 0.5 THEN 1 ELSE 0 END +
                  CASE WHEN MonthlyIncome < 2000 OR MonthlyIncome IS NULL THEN 1 ELSE 0 END) = 2 
            THEN '2. Medium Risk'
            ELSE '1. Low Risk'
        END
),
age_cohort_performance AS (
    SELECT 
        CASE 
            WHEN age < 30 THEN '1. 18-29'
            WHEN age < 40 THEN '2. 30-39'
            WHEN age < 50 THEN '3. 40-49'
            WHEN age < 60 THEN '4. 50-59'
            ELSE '5. 60+'
        END AS age_cohort,
        COUNT(*) AS cohort_size,
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS cohort_default_rate,
        ROUND(AVG(MonthlyIncome), 0) AS cohort_avg_income,
        ROUND(AVG(DebtRatio), 3) AS cohort_avg_debt_ratio
    FROM [Credit Risk Analysis].dbo.[training$]
    WHERE age IS NOT NULL
    GROUP BY 
        CASE 
            WHEN age < 30 THEN '1. 18-29'
            WHEN age < 40 THEN '2. 30-39'
            WHEN age < 50 THEN '3. 40-49'
            WHEN age < 60 THEN '4. 50-59'
            ELSE '5. 60+'
        END
),
income_tier_analysis AS (
    SELECT 
        CASE 
            WHEN MonthlyIncome IS NULL THEN '1. Unknown'
            WHEN MonthlyIncome < 3000 THEN '2. Under $3k'
            WHEN MonthlyIncome < 6000 THEN '3. $3k-$6k'
            WHEN MonthlyIncome < 10000 THEN '4. $6k-$10k'
            ELSE '5. $10k+'
        END AS income_tier,
        COUNT(*) AS tier_size,
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS tier_default_rate
    FROM [Credit Risk Analysis].dbo.[training$]
    GROUP BY 
        CASE 
            WHEN MonthlyIncome IS NULL THEN '1. Unknown'
            WHEN MonthlyIncome < 3000 THEN '2. Under $3k'
            WHEN MonthlyIncome < 6000 THEN '3. $3k-$6k'
            WHEN MonthlyIncome < 10000 THEN '4. $6k-$10k'
            ELSE '5. $10k+'
        END
),
top_risk_indicators AS (
    SELECT 
        '1. High Utilization (>80%)' AS risk_indicator,
        COUNT(*) AS affected_customers,
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_with_indicator
    FROM [Credit Risk Analysis].dbo.[training$]
    WHERE RevolvingUtilizationOfUnsecuredLines > 0.80
    
    UNION ALL
    
    SELECT 
        '2. 90+ Days Late History',
        COUNT(*),
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2)
    FROM [Credit Risk Analysis].dbo.[training$]
    WHERE NumberOfTimes90DaysLate > 0
    
    UNION ALL
    
    SELECT 
        '3. High Debt Ratio (>50%)',
        COUNT(*),
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2)
    FROM [Credit Risk Analysis].dbo.[training$]
    WHERE DebtRatio > 0.5
    
    UNION ALL
    
    SELECT 
        '4. Low Income (<$2k)',
        COUNT(*),
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2)
    FROM [Credit Risk Analysis].dbo.[training$]
    WHERE MonthlyIncome < 2000 OR MonthlyIncome IS NULL
),
dashboard_output AS (
    SELECT 
        1 AS sort_order,
        '=== PORTFOLIO OVERVIEW ===' AS section,
        CAST(NULL AS NVARCHAR(100)) AS metric,
        CAST(NULL AS NVARCHAR(100)) AS value,
        CAST(NULL AS NVARCHAR(100)) AS additional_info
    
    UNION ALL
    SELECT 2, '', 'Total Customers', CAST(total_customers AS NVARCHAR(100)), NULL
    FROM portfolio_overview
    
    UNION ALL
    SELECT 3, '', 'Total Defaulters', CAST(total_defaulters AS NVARCHAR(100)), NULL
    FROM portfolio_overview
    
    UNION ALL
    SELECT 4, '', 'Overall Default Rate', CAST(overall_default_rate AS NVARCHAR(100)) + '%', NULL
    FROM portfolio_overview
    
    UNION ALL
    SELECT 5, '', 'Average Customer Age', CAST(avg_customer_age AS NVARCHAR(100)) + ' years', NULL
    FROM portfolio_overview
    
    UNION ALL
    SELECT 6, '', 'Average Monthly Income', '$' + CAST(avg_monthly_income AS NVARCHAR(100)), NULL
    FROM portfolio_overview
    
    UNION ALL
    SELECT 7, '', 'Average Debt Ratio', CAST(avg_debt_ratio AS NVARCHAR(100)), NULL
    FROM portfolio_overview
    
    UNION ALL
    SELECT 8, '', 'Average Utilization Rate', CAST(avg_utilization_rate AS NVARCHAR(100)), NULL
    FROM portfolio_overview
    
    UNION ALL
    SELECT 9, '', '', '', ''
    
    UNION ALL
    SELECT 10, '=== RISK SEGMENTATION ===', NULL, NULL, NULL
    
    UNION ALL
    SELECT 
        10 + ROW_NUMBER() OVER (ORDER BY risk_category),
        '', 
        risk_category, 
        CAST(customer_count AS NVARCHAR(100)) + ' customers', 
        'Default Rate: ' + CAST(default_rate AS NVARCHAR(100)) + '%'
    FROM risk_segment_distribution
    
    UNION ALL
    SELECT 14, '', '', '', ''
    
    UNION ALL
    SELECT 15, '=== AGE COHORT PERFORMANCE ===', NULL, NULL, NULL
    
    UNION ALL
    SELECT 
        15 + ROW_NUMBER() OVER (ORDER BY age_cohort),
        '', 
        age_cohort, 
        CAST(cohort_size AS NVARCHAR(100)) + ' customers', 
        'Default Rate: ' + CAST(cohort_default_rate AS NVARCHAR(100)) + '%'
    FROM age_cohort_performance
    
    UNION ALL
    SELECT 21, '', '', '', ''
    
    UNION ALL
    SELECT 22, '=== INCOME TIER ANALYSIS ===', NULL, NULL, NULL
    
    UNION ALL
    SELECT 
        22 + ROW_NUMBER() OVER (ORDER BY income_tier),
        '', 
        income_tier, 
        CAST(tier_size AS NVARCHAR(100)) + ' customers', 
        'Default Rate: ' + CAST(tier_default_rate AS NVARCHAR(100)) + '%'
    FROM income_tier_analysis
    
    UNION ALL
    SELECT 28, '', '', '', ''
    
    UNION ALL
    SELECT 29, '=== TOP RISK INDICATORS ===', NULL, NULL, NULL
    
    UNION ALL
    SELECT 
        29 + ROW_NUMBER() OVER (ORDER BY risk_indicator),
        '', 
        risk_indicator, 
        CAST(affected_customers AS NVARCHAR(100)) + ' customers', 
        'Default Rate: ' + CAST(default_rate_with_indicator AS NVARCHAR(100)) + '%'
    FROM top_risk_indicators
)
SELECT 
    section,
    metric,
    value,
    additional_info
FROM dashboard_output
ORDER BY sort_order;
