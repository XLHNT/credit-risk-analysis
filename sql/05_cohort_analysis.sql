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



