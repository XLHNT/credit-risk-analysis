-- Q14: TREND SIMULATION WITH COMPARATIVE ANALYSIS
-- If we split our portfolio into two time periods, how would we measure period-over-period performance changes?

WITH simulated_periods AS (
    SELECT 
        Id,
        age,
        MonthlyIncome,
        SeriousDlqin2yrs,
        DebtRatio,
        RevolvingUtilizationOfUnsecuredLines,
        
        CASE 
            WHEN CAST(Id AS BIGINT) % 2 = 0 THEN 'Period 1 (Older Cohort)'
            ELSE 'Period 2 (Newer Cohort)'
        END AS time_period,
        
        CASE 
            WHEN age < 40 THEN 'Under 40'
            WHEN age < 60 THEN '40-59'
            ELSE '60+'
        END AS age_bracket
    FROM [Credit Risk Analysis].dbo.[training$]
    WHERE age IS NOT NULL
),
period_metrics AS (
    SELECT 
        time_period,
        age_bracket,
        COUNT(*) AS customers,
        ROUND(AVG(MonthlyIncome), 0) AS avg_income,
        ROUND(AVG(DebtRatio), 3) AS avg_debt_ratio,
        ROUND(AVG(RevolvingUtilizationOfUnsecuredLines), 3) AS avg_utilization,
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct
    FROM simulated_periods
    GROUP BY time_period, age_bracket
),
comparative_analysis AS (
    SELECT 
        age_bracket,
        
        MAX(CASE WHEN time_period = 'Period 1 (Older Cohort)' THEN customers END) AS period1_customers,
        MAX(CASE WHEN time_period = 'Period 2 (Newer Cohort)' THEN customers END) AS period2_customers,
        
        MAX(CASE WHEN time_period = 'Period 1 (Older Cohort)' THEN avg_income END) AS period1_avg_income,
        MAX(CASE WHEN time_period = 'Period 2 (Newer Cohort)' THEN avg_income END) AS period2_avg_income,
        
        MAX(CASE WHEN time_period = 'Period 1 (Older Cohort)' THEN default_rate_pct END) AS period1_default_rate,
        MAX(CASE WHEN time_period = 'Period 2 (Newer Cohort)' THEN default_rate_pct END) AS period2_default_rate
    FROM period_metrics
    GROUP BY age_bracket
)
SELECT 
    age_bracket,
    period1_customers,
    period2_customers,
    (period2_customers - period1_customers) AS customer_change,
    
    period1_avg_income,
    period2_avg_income,
    ROUND(period2_avg_income - period1_avg_income, 0) AS income_change,
    ROUND(100.0 * (period2_avg_income - period1_avg_income) / NULLIF(period1_avg_income, 0), 2) AS income_change_pct,
    
    period1_default_rate,
    period2_default_rate,
    ROUND(period2_default_rate - period1_default_rate, 2) AS default_rate_change_points,
    
    CASE 
        WHEN period2_default_rate > period1_default_rate THEN 'DETERIORATING'
        WHEN period2_default_rate < period1_default_rate THEN 'IMPROVING'
        ELSE 'STABLE'
    END AS risk_trend
FROM comparative_analysis
ORDER BY age_bracket;



-- Q16: ADVANCED FEATURE ENGINEERING FOR PREDICTIVE MODELING
-- What derived features and interaction terms could improve credit risk prediction models? Calculate feature importance indicators.

WITH engineered_features AS (
    SELECT 
        Id,
        SeriousDlqin2yrs,
        
        age,
        MonthlyIncome,
        DebtRatio,
        RevolvingUtilizationOfUnsecuredLines,
        NumberOfOpenCreditLinesAndLoans,
        
        ROUND(RevolvingUtilizationOfUnsecuredLines * DebtRatio, 4) AS utilization_debt_interaction,
        ROUND(age * COALESCE(NumberOfDependents, 0), 2) AS age_dependent_interaction,
        ROUND(MonthlyIncome / NULLIF(NumberOfOpenCreditLinesAndLoans, 0), 2) AS income_per_credit_line,
        
        ROUND(DebtRatio / NULLIF(RevolvingUtilizationOfUnsecuredLines, 0), 3) AS debt_to_utilization_ratio,
        ROUND(MonthlyIncome / NULLIF(age, 0), 2) AS income_age_ratio,
        
        CASE 
            WHEN age < 30 AND MonthlyIncome < 3000 THEN 1 
            ELSE 0 
        END AS young_low_income_flag,
        
        CASE 
            WHEN RevolvingUtilizationOfUnsecuredLines > 0.9 
                 AND DebtRatio > 0.5 THEN 1 
            ELSE 0 
        END AS double_leverage_flag,
        
        CASE 
            WHEN NumberOfTimes90DaysLate > 0 
                 AND RevolvingUtilizationOfUnsecuredLines > 0.8 THEN 1 
            ELSE 0 
        END AS severe_risk_combo_flag,
        
        NTILE(10) OVER (ORDER BY MonthlyIncome) AS income_decile,
        NTILE(10) OVER (ORDER BY age) AS age_decile,
        NTILE(10) OVER (ORDER BY DebtRatio) AS debt_ratio_decile
    FROM [Credit Risk Analysis].dbo.[training$]
)
SELECT 
    'utilization_debt_interaction' AS feature_name,
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN utilization_debt_interaction END), 4) AS avg_value_defaulters,
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN utilization_debt_interaction END), 4) AS avg_value_non_defaulters,
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN utilization_debt_interaction END) - 
          AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN utilization_debt_interaction END), 4) AS mean_difference
FROM engineered_features

UNION ALL

SELECT 
    'income_per_credit_line',
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN income_per_credit_line END), 2),
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN income_per_credit_line END), 2),
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN income_per_credit_line END) - 
          AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN income_per_credit_line END), 2)
FROM engineered_features

UNION ALL

SELECT 
    'young_low_income_flag',
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN CAST(young_low_income_flag AS FLOAT) END), 4),
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN CAST(young_low_income_flag AS FLOAT) END), 4),
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN CAST(young_low_income_flag AS FLOAT) END) - 
          AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN CAST(young_low_income_flag AS FLOAT) END), 4)
FROM engineered_features

UNION ALL

SELECT 
    'double_leverage_flag',
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN CAST(double_leverage_flag AS FLOAT) END), 4),
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN CAST(double_leverage_flag AS FLOAT) END), 4),
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN CAST(double_leverage_flag AS FLOAT) END) - 
          AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN CAST(double_leverage_flag AS FLOAT) END), 4)
FROM engineered_features

UNION ALL

SELECT 
    'severe_risk_combo_flag',
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN CAST(severe_risk_combo_flag AS FLOAT) END), 4),
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN CAST(severe_risk_combo_flag AS FLOAT) END), 4),
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN CAST(severe_risk_combo_flag AS FLOAT) END) - 
          AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN CAST(severe_risk_combo_flag AS FLOAT) END), 4)
FROM engineered_features;

