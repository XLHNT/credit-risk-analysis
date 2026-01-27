--2.
-- Age distribution summary statistics

SELECT 
    MIN(age) AS youngest_customer,
    MAX(age) AS oldest_customer,
    ROUND(AVG(age), 1) AS average_age,
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 1 THEN age END), 1) AS avg_age_defaulters,
    ROUND(AVG(CASE WHEN SeriousDlqin2yrs = 0 THEN age END), 1) AS avg_age_non_defaulters
FROM [Credit Risk Analysis].dbo.[training$];

-- Age group distribution
SELECT 
    CASE 
        WHEN age < 30 THEN '18-29: Young Adults'
        WHEN age < 40 THEN '30-39: Early Career'
        WHEN age < 50 THEN '40-49: Mid Career'
        WHEN age < 60 THEN '50-59: Late Career'
        WHEN age < 70 THEN '60-69: Pre-Retirement'
        ELSE '70+: Senior'
    END AS age_group,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    SUM(SeriousDlqin2yrs) AS defaulters,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate
FROM [Credit Risk Analysis].dbo.[training$]
WHERE age IS NOT NULL
GROUP BY 
    CASE 
        WHEN age < 30 THEN '18-29: Young Adults'
        WHEN age < 40 THEN '30-39: Early Career'
        WHEN age < 50 THEN '40-49: Mid Career'
        WHEN age < 60 THEN '50-59: Late Career'
        WHEN age < 70 THEN '60-69: Pre-Retirement'
        ELSE '70+: Senior'
    END
ORDER BY age_group;



--6.
-- Income bracket analysis with debt metrics

SELECT 
    CASE 
        WHEN MonthlyIncome IS NULL THEN '0. Income Unknown'
        WHEN MonthlyIncome < 2000 THEN '1. Under $2k'
        WHEN MonthlyIncome < 4000 THEN '2. $2k-$4k'
        WHEN MonthlyIncome < 6000 THEN '3. $4k-$6k'
        WHEN MonthlyIncome < 8000 THEN '4. $6k-$8k'
        WHEN MonthlyIncome < 10000 THEN '5. $8k-$10k'
        ELSE '6. $10k+'
    END AS income_bracket,
    
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    
    ROUND(AVG(MonthlyIncome), 0) AS avg_income,
    ROUND(MIN(MonthlyIncome), 0) AS min_income,
    ROUND(MAX(MonthlyIncome), 0) AS max_income,
    
    ROUND(AVG(DebtRatio), 3) AS avg_debt_ratio,
    ROUND(AVG(RevolvingUtilizationOfUnsecuredLines), 3) AS avg_utilization,
    
    SUM(SeriousDlqin2yrs) AS defaulters,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct,
    
    ROUND(AVG(NumberOfTimes90DaysLate), 2) AS avg_90day_late,
    ROUND(AVG([NumberOfTime30-59DaysPastDueNotWorse]), 2) AS avg_30day_late
    
FROM [Credit Risk Analysis].dbo.[training$]
GROUP BY 
    CASE 
        WHEN MonthlyIncome IS NULL THEN '0. Income Unknown'
        WHEN MonthlyIncome < 2000 THEN '1. Under $2k'
        WHEN MonthlyIncome < 4000 THEN '2. $2k-$4k'
        WHEN MonthlyIncome < 6000 THEN '3. $4k-$6k'
        WHEN MonthlyIncome < 8000 THEN '4. $6k-$8k'
        WHEN MonthlyIncome < 10000 THEN '5. $8k-$10k'
        ELSE '6. $10k+'
    END
ORDER BY income_bracket;



--8.
-- Comprehensive age-based financial behavior analysis

SELECT 
    CASE 
        WHEN age < 25 THEN '1. 18-24: Young Adults'
        WHEN age < 35 THEN '2. 25-34: Early Career'
        WHEN age < 45 THEN '3. 35-44: Mid Career'
        WHEN age < 55 THEN '4. 45-54: Peak Earning'
        WHEN age < 65 THEN '5. 55-64: Pre-Retirement'
        ELSE '6. 65+: Retirement Age'
    END AS age_segment,
    
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_portfolio,
    
    ROUND(AVG(age), 1) AS avg_age,
    ROUND(AVG(COALESCE(NumberOfDependents, 0)), 2) AS avg_dependents,
    
    ROUND(AVG(MonthlyIncome), 0) AS avg_monthly_income,
    ROUND(AVG(DebtRatio), 3) AS avg_debt_ratio,
    
    ROUND(AVG(RevolvingUtilizationOfUnsecuredLines), 3) AS avg_utilization_rate,
    ROUND(AVG(NumberOfOpenCreditLinesAndLoans), 1) AS avg_credit_accounts,
    
    ROUND(AVG([NumberOfTime30-59DaysPastDueNotWorse]), 2) AS avg_30day_late,
    ROUND(AVG([NumberOfTime60-89DaysPastDueNotWorse]), 2) AS avg_60day_late,
    ROUND(AVG(NumberOfTimes90DaysLate), 2) AS avg_90day_late,
    
    SUM(SeriousDlqin2yrs) AS total_defaulters,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct
    
FROM [Credit Risk Analysis].dbo.[training$]
WHERE age IS NOT NULL
GROUP BY 
    CASE 
        WHEN age < 25 THEN '1. 18-24: Young Adults'
        WHEN age < 35 THEN '2. 25-34: Early Career'
        WHEN age < 45 THEN '3. 35-44: Mid Career'
        WHEN age < 55 THEN '4. 45-54: Peak Earning'
        WHEN age < 65 THEN '5. 55-64: Pre-Retirement'
        ELSE '6. 65+: Retirement Age'
    END
ORDER BY age_segment;




--9.
-- Dependents analysis with NULL handling

SELECT 
    CASE 
        WHEN NumberOfDependents IS NULL THEN '0. Unknown'
        WHEN NumberOfDependents = 0 THEN '1. No Dependents'
        WHEN NumberOfDependents BETWEEN 1 AND 2 THEN '2. 1-2 Dependents'
        WHEN NumberOfDependents BETWEEN 3 AND 4 THEN '3. 3-4 Dependents'
        ELSE '4. 5+ Dependents'
    END AS dependent_category,
    
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_customers,
    
    -- Demographics
    ROUND(AVG(age), 1) AS avg_age,
    ROUND(AVG(COALESCE(NumberOfDependents, 0)), 2) AS avg_dependents_count,
    
    -- Financial profile
    ROUND(AVG(MonthlyIncome), 0) AS avg_monthly_income,
    ROUND(AVG(DebtRatio), 3) AS avg_debt_ratio,
    ROUND(AVG(RevolvingUtilizationOfUnsecuredLines), 3) AS avg_credit_utilization,
    
    -- Credit behavior
    ROUND(AVG(NumberOfOpenCreditLinesAndLoans), 1) AS avg_credit_lines,
    ROUND(AVG(NumberRealEstateLoansOrLines), 2) AS avg_real_estate_loans,
    
    -- Risk metrics
    SUM(SeriousDlqin2yrs) AS defaulters,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct,
    
    -- Late payment patterns
    ROUND(AVG(NumberOfTimes90DaysLate), 2) AS avg_severe_late_payments
    
FROM [Credit Risk Analysis].dbo.[training$]
GROUP BY 
    CASE 
        WHEN NumberOfDependents IS NULL THEN '0. Unknown'
        WHEN NumberOfDependents = 0 THEN '1. No Dependents'
        WHEN NumberOfDependents BETWEEN 1 AND 2 THEN '2. 1-2 Dependents'
        WHEN NumberOfDependents BETWEEN 3 AND 4 THEN '3. 3-4 Dependents'
        ELSE '4. 5+ Dependents'
    END
ORDER BY dependent_category;

-- Additional: Dependents impact within same income bracket
SELECT 
    CASE 
        WHEN MonthlyIncome < 4000 THEN 'Low Income (<$4k)'
        WHEN MonthlyIncome < 8000 THEN 'Middle Income ($4k-$8k)'
        ELSE 'High Income ($8k+)'
    END AS income_level,
    
    CASE 
        WHEN NumberOfDependents IS NULL OR NumberOfDependents = 0 THEN 'No Dependents'
        ELSE 'Has Dependents'
    END AS dependent_status,
    
    COUNT(*) AS customers,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct,
    ROUND(AVG(DebtRatio), 3) AS avg_debt_ratio
    
FROM [Credit Risk Analysis].dbo.[training$]
WHERE MonthlyIncome IS NOT NULL
GROUP BY 
    CASE 
        WHEN MonthlyIncome < 4000 THEN 'Low Income (<$4k)'
        WHEN MonthlyIncome < 8000 THEN 'Middle Income ($4k-$8k)'
        ELSE 'High Income ($8k+)'
    END,
    CASE 
        WHEN NumberOfDependents IS NULL OR NumberOfDependents = 0 THEN 'No Dependents'
        ELSE 'Has Dependents'
    END
ORDER BY income_level, dependent_status;




