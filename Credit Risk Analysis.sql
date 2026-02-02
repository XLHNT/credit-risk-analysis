--1.
-- Calculate missing value percentages for each column

SELECT 
    COUNT(*) AS total_records,
    
    -- Count and percentage of NULL values for each column
    COUNT(*) - COUNT(SeriousDlqin2yrs) AS missing_delinquency,
    ROUND(100.0 * (COUNT(*) - COUNT(SeriousDlqin2yrs)) / COUNT(*), 2) AS pct_missing_delinquency,
    
    COUNT(*) - COUNT(RevolvingUtilizationOfUnsecuredLines) AS missing_utilization,
    ROUND(100.0 * (COUNT(*) - COUNT(RevolvingUtilizationOfUnsecuredLines)) / COUNT(*), 2) AS pct_missing_utilization,
    
    COUNT(*) - COUNT(age) AS missing_age,
    ROUND(100.0 * (COUNT(*) - COUNT(age)) / COUNT(*), 2) AS pct_missing_age,
    
    COUNT(*) - COUNT(MonthlyIncome) AS missing_income,
    ROUND(100.0 * (COUNT(*) - COUNT(MonthlyIncome)) / COUNT(*), 2) AS pct_missing_income,
    
    COUNT(*) - COUNT(NumberOfDependents) AS missing_dependents,
    ROUND(100.0 * (COUNT(*) - COUNT(NumberOfDependents)) / COUNT(*), 2) AS pct_missing_dependents,
    
    COUNT(*) - COUNT(DebtRatio) AS missing_debt_ratio,
    ROUND(100.0 * (COUNT(*) - COUNT(DebtRatio)) / COUNT(*), 2) AS pct_missing_debt_ratio
    
FROM [Credit Risk Analysis].dbo.[training$];





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





--7.
-- Credit product portfolio analysis

SELECT 
    CASE 
        WHEN NumberOfOpenCreditLinesAndLoans = 0 THEN '0: No Credit'
        WHEN NumberOfOpenCreditLinesAndLoans BETWEEN 1 AND 3 THEN '1-3: Minimal'
        WHEN NumberOfOpenCreditLinesAndLoans BETWEEN 4 AND 6 THEN '4-6: Moderate'
        WHEN NumberOfOpenCreditLinesAndLoans BETWEEN 7 AND 10 THEN '7-10: Substantial'
        ELSE '11+: Extensive'
    END AS credit_product_category,
    
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_customers,
    
    -- Product statistics
    ROUND(AVG(NumberOfOpenCreditLinesAndLoans), 1) AS avg_products,
    ROUND(AVG(NumberRealEstateLoansOrLines), 2) AS avg_real_estate_loans,
    
    -- Risk correlation
    SUM(SeriousDlqin2yrs) AS defaulters,
    ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct,
    
    -- Financial behavior
    ROUND(AVG(MonthlyIncome), 0) AS avg_income,
    ROUND(AVG(DebtRatio), 3) AS avg_debt_ratio
    
FROM [Credit Risk Analysis].dbo.[training$]
GROUP BY 
    CASE 
        WHEN NumberOfOpenCreditLinesAndLoans = 0 THEN '0: No Credit'
        WHEN NumberOfOpenCreditLinesAndLoans BETWEEN 1 AND 3 THEN '1-3: Minimal'
        WHEN NumberOfOpenCreditLinesAndLoans BETWEEN 4 AND 6 THEN '4-6: Moderate'
        WHEN NumberOfOpenCreditLinesAndLoans BETWEEN 7 AND 10 THEN '7-10: Substantial'
        ELSE '11+: Extensive'
    END
ORDER BY credit_product_category;

-- Comparison: Defaulters vs Non-Defaulters
SELECT 
    SeriousDlqin2yrs,
    CASE WHEN SeriousDlqin2yrs = 1 THEN 'Defaulted' ELSE 'Did Not Default' END AS status,
    COUNT(*) AS customers,
    ROUND(AVG(NumberOfOpenCreditLinesAndLoans), 2) AS avg_credit_lines,
    ROUND(AVG(NumberRealEstateLoansOrLines), 2) AS avg_real_estate_loans,
    ROUND(AVG(NumberOfOpenCreditLinesAndLoans + NumberRealEstateLoansOrLines), 2) AS avg_total_products
FROM [Credit Risk Analysis].dbo.[training$]
GROUP BY SeriousDlqin2yrs
ORDER BY SeriousDlqin2yrs;





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





-- Q13: MULTI-DIMENSIONAL CUSTOMER SEGMENTATION
-- How can we create actionable customer segments using multiple risk dimensions simultaneously? What are the characteristics of each segment?

WITH customer_segments AS (
    SELECT 
        Id,
        
        CASE 
            WHEN age < 35 THEN 'Young'
            WHEN age < 55 THEN 'Middle-Aged'
            ELSE 'Senior'
        END AS age_segment,
        
        CASE 
            WHEN MonthlyIncome IS NULL THEN 'Unknown'
            WHEN MonthlyIncome < 4000 THEN 'Low'
            WHEN MonthlyIncome < 8000 THEN 'Medium'
            ELSE 'High'
        END AS income_segment,
        
        CASE 
            WHEN RevolvingUtilizationOfUnsecuredLines IS NULL THEN 'Unknown'
            WHEN RevolvingUtilizationOfUnsecuredLines <= 0.30 THEN 'Low'
            WHEN RevolvingUtilizationOfUnsecuredLines <= 0.70 THEN 'Medium'
            ELSE 'High'
        END AS utilization_segment,
        
        CASE 
            WHEN NumberOfTimes90DaysLate = 0 
                 AND [NumberOfTime30-59DaysPastDueNotWorse] <= 1 THEN 'Good'
            WHEN NumberOfTimes90DaysLate = 0 
                 AND [NumberOfTime30-59DaysPastDueNotWorse] <= 3 THEN 'Fair'
            ELSE 'Poor'
        END AS payment_history_segment,
        
        SeriousDlqin2yrs,
        age,
        MonthlyIncome,
        DebtRatio,
        RevolvingUtilizationOfUnsecuredLines
    FROM [Credit Risk Analysis].dbo.[training$]
),
segment_profiles AS (
    SELECT 
        CONCAT(age_segment, ' | ', income_segment, ' Income | ', 
               utilization_segment, ' Util | ', payment_history_segment, ' History') AS customer_profile,
        age_segment,
        income_segment,
        utilization_segment,
        payment_history_segment,
        COUNT(*) AS segment_size,
        ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_portfolio,
        
        ROUND(AVG(age), 1) AS avg_age,
        ROUND(AVG(MonthlyIncome), 0) AS avg_income,
        ROUND(AVG(DebtRatio), 3) AS avg_debt_ratio,
        ROUND(AVG(RevolvingUtilizationOfUnsecuredLines), 3) AS avg_utilization,
        
        SUM(SeriousDlqin2yrs) AS defaulters,
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS default_rate_pct
    FROM customer_segments
    GROUP BY age_segment, income_segment, utilization_segment, payment_history_segment
)
SELECT 
    customer_profile,
    segment_size,
    pct_of_portfolio,
    avg_age,
    avg_income,
    avg_debt_ratio,
    avg_utilization,
    defaulters,
    default_rate_pct,
    CASE 
        WHEN default_rate_pct > 15 THEN 'HIGH RISK'
        WHEN default_rate_pct > 8 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS risk_classification
FROM segment_profiles
WHERE segment_size > 100
ORDER BY default_rate_pct DESC, segment_size DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;





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





-- Q15: COHORT RISK PROGRESSION ANALYSIS
-- How does risk evolve across different credit line cohorts? 
-- Which cohorts show the most deviation from portfolio averages?

WITH credit_line_cohorts AS (
    SELECT 
        Id,
        
        CASE 
            WHEN NumberOfOpenCreditLinesAndLoans BETWEEN 0 AND 3 THEN '1. 0-3 Lines'
            WHEN NumberOfOpenCreditLinesAndLoans BETWEEN 4 AND 6 THEN '2. 4-6 Lines'
            WHEN NumberOfOpenCreditLinesAndLoans BETWEEN 7 AND 10 THEN '3. 7-10 Lines'
            ELSE '4. 11+ Lines'
        END AS credit_line_cohort,
        
        NumberOfOpenCreditLinesAndLoans,
        age,
        MonthlyIncome,
        DebtRatio,
        RevolvingUtilizationOfUnsecuredLines,
        SeriousDlqin2yrs
    FROM [Credit Risk Analysis].dbo.[training$]
),
cohort_metrics AS (
    SELECT 
        credit_line_cohort,
        COUNT(*) AS cohort_size,
        
        ROUND(AVG(age), 1) AS avg_age,
        ROUND(AVG(MonthlyIncome), 0) AS avg_income,
        ROUND(AVG(DebtRatio), 3) AS avg_debt_ratio,
        ROUND(AVG(RevolvingUtilizationOfUnsecuredLines), 3) AS avg_utilization,
        ROUND(AVG(NumberOfOpenCreditLinesAndLoans), 1) AS avg_credit_lines,
        
        SUM(SeriousDlqin2yrs) AS defaulters,
        ROUND(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*), 2) AS cohort_default_rate,
        
        ROUND(AVG(100.0 * SUM(SeriousDlqin2yrs) / COUNT(*)) OVER(), 2) AS portfolio_avg_default_rate
    FROM credit_line_cohorts
    GROUP BY credit_line_cohort
)
SELECT 
    credit_line_cohort,
    cohort_size,
    ROUND(100.0 * cohort_size / SUM(cohort_size) OVER(), 2) AS pct_of_portfolio,
    
    avg_age,
    avg_income,
    avg_debt_ratio,
    avg_utilization,
    avg_credit_lines,
    
    defaulters,
    cohort_default_rate,
    portfolio_avg_default_rate,
    
    ROUND(cohort_default_rate - portfolio_avg_default_rate, 2) AS deviation_from_portfolio,
    
    CASE 
        WHEN cohort_default_rate > portfolio_avg_default_rate * 1.5 THEN 'HIGH RISK COHORT'
        WHEN cohort_default_rate > portfolio_avg_default_rate * 1.2 THEN 'ELEVATED RISK'
        WHEN cohort_default_rate < portfolio_avg_default_rate * 0.8 THEN 'LOW RISK COHORT'
        ELSE 'AVERAGE RISK'
    END AS risk_classification
FROM cohort_metrics
ORDER BY credit_line_cohort;





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





-- Q17: DATA ANOMALY DETECTION AND QUALITY VALIDATION
-- Business Question: What data anomalies and quality issues exist that could compromise analysis accuracy? Identify outliers using statistical methods.

-- Part A: Statistical Outlier Detection
WITH statistical_baseline AS (
    SELECT 
        AVG(CAST(age AS FLOAT)) AS mean_age,
        STDEV(CAST(age AS FLOAT)) AS std_age,
        AVG(CAST(MonthlyIncome AS FLOAT)) AS mean_income,
        STDEV(CAST(MonthlyIncome AS FLOAT)) AS std_income,
        AVG(CAST(DebtRatio AS FLOAT)) AS mean_debt_ratio,
        STDEV(CAST(DebtRatio AS FLOAT)) AS std_debt_ratio,
        AVG(CAST(RevolvingUtilizationOfUnsecuredLines AS FLOAT)) AS mean_utilization,
        STDEV(CAST(RevolvingUtilizationOfUnsecuredLines AS FLOAT)) AS std_utilization
    FROM [Credit Risk Analysis].dbo.[training$]
),
anomaly_detection AS (
    SELECT 
        c.Id,
        c.age,
        c.MonthlyIncome,
        c.DebtRatio,
        c.RevolvingUtilizationOfUnsecuredLines,
        c.NumberOfDependents,
        c.SeriousDlqin2yrs,
        
        -- Calculate z-scores
        CASE 
            WHEN s.std_age > 0 THEN ROUND((c.age - s.mean_age) / s.std_age, 2)
            ELSE 0
        END AS age_zscore,
        CASE 
            WHEN s.std_income > 0 AND c.MonthlyIncome IS NOT NULL 
            THEN ROUND((c.MonthlyIncome - s.mean_income) / s.std_income, 2)
            ELSE NULL
        END AS income_zscore,
        CASE 
            WHEN s.std_debt_ratio > 0 AND c.DebtRatio IS NOT NULL 
            THEN ROUND((c.DebtRatio - s.mean_debt_ratio) / s.std_debt_ratio, 2)
            ELSE NULL
        END AS debt_ratio_zscore,
        CASE 
            WHEN s.std_utilization > 0 AND c.RevolvingUtilizationOfUnsecuredLines IS NOT NULL 
            THEN ROUND((c.RevolvingUtilizationOfUnsecuredLines - s.mean_utilization) / s.std_utilization, 2)
            ELSE NULL
        END AS utilization_zscore,
        
        -- Anomaly flags
        CASE WHEN c.age > 100 OR c.age < 18 THEN 1 ELSE 0 END AS impossible_age_flag,
        CASE WHEN c.RevolvingUtilizationOfUnsecuredLines > 2 THEN 1 ELSE 0 END AS extreme_utilization_flag,
        CASE WHEN c.MonthlyIncome IS NULL OR c.MonthlyIncome <= 0 THEN 1 ELSE 0 END AS invalid_income_flag,
        CASE WHEN c.DebtRatio < 0 THEN 1 ELSE 0 END AS negative_debt_ratio_flag,
        CASE WHEN c.NumberOfDependents > 10 THEN 1 ELSE 0 END AS extreme_dependents_flag
    FROM [Credit Risk Analysis].dbo.[training$] c
    CROSS JOIN statistical_baseline s
),
anomaly_summary AS (
    SELECT 
        Id,
        age,
        MonthlyIncome,
        DebtRatio,
        RevolvingUtilizationOfUnsecuredLines,
        NumberOfDependents,
        
        (impossible_age_flag + extreme_utilization_flag + invalid_income_flag + 
         negative_debt_ratio_flag + extreme_dependents_flag) AS total_anomaly_flags,
        
        CASE 
            WHEN ABS(ISNULL(age_zscore, 0)) > 3 THEN 'Age Outlier'
            WHEN ABS(ISNULL(income_zscore, 0)) > 3 THEN 'Income Outlier'
            WHEN ABS(ISNULL(debt_ratio_zscore, 0)) > 3 THEN 'Debt Ratio Outlier'
            WHEN ABS(ISNULL(utilization_zscore, 0)) > 3 THEN 'Utilization Outlier'
            ELSE 'Normal'
        END AS statistical_outlier_type,
        
        age_zscore,
        income_zscore,
        debt_ratio_zscore,
        utilization_zscore,
        
        -- For sorting (handle NULLs)
        (ABS(ISNULL(age_zscore, 0)) + ABS(ISNULL(income_zscore, 0)) + 
         ABS(ISNULL(debt_ratio_zscore, 0)) + ABS(ISNULL(utilization_zscore, 0))) AS combined_zscore
    FROM anomaly_detection
)
SELECT TOP 500
    Id,
    age,
    MonthlyIncome,
    DebtRatio,
    RevolvingUtilizationOfUnsecuredLines,
    NumberOfDependents,
    total_anomaly_flags,
    statistical_outlier_type,
    age_zscore,
    income_zscore,
    debt_ratio_zscore,
    utilization_zscore
FROM anomaly_summary
WHERE total_anomaly_flags > 0 OR statistical_outlier_type != 'Normal'
ORDER BY total_anomaly_flags DESC, combined_zscore DESC;


-- Part B: Anomaly Summary Report
SELECT 
    'Impossible Age Values (>100 or <18)' AS anomaly_type,
    COUNT(*) AS affected_records,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM [Credit Risk Analysis].dbo.[training$]), 2) AS pct_of_dataset
FROM [Credit Risk Analysis].dbo.[training$]
WHERE age > 100 OR age < 18

UNION ALL

SELECT 
    'Extreme Utilization (>200%)',
    COUNT(*),
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM [Credit Risk Analysis].dbo.[training$]), 2)
FROM [Credit Risk Analysis].dbo.[training$]
WHERE RevolvingUtilizationOfUnsecuredLines > 2

UNION ALL

SELECT 
    'Invalid or Missing Income',
    COUNT(*),
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM [Credit Risk Analysis].dbo.[training$]), 2)
FROM [Credit Risk Analysis].dbo.[training$]
WHERE MonthlyIncome IS NULL OR MonthlyIncome <= 0

UNION ALL

SELECT 
    'Negative Debt Ratio',
    COUNT(*),
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM [Credit Risk Analysis].dbo.[training$]), 2)
FROM [Credit Risk Analysis].dbo.[training$]
WHERE DebtRatio < 0

UNION ALL

SELECT 
    'Extreme Dependents (>10)',
    COUNT(*),
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM [Credit Risk Analysis].dbo.[training$]), 2)
FROM [Credit Risk Analysis].dbo.[training$]
WHERE NumberOfDependents > 10

UNION ALL

SELECT 
    'Total Anomalies Detected',
    COUNT(DISTINCT Id),
    ROUND(100.0 * COUNT(DISTINCT Id) / (SELECT COUNT(*) FROM [Credit Risk Analysis].dbo.[training$]), 2)
FROM [Credit Risk Analysis].dbo.[training$]
WHERE age > 100 OR age < 18 
   OR RevolvingUtilizationOfUnsecuredLines > 2
   OR MonthlyIncome IS NULL OR MonthlyIncome <= 0
   OR DebtRatio < 0
   OR NumberOfDependents > 10;





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