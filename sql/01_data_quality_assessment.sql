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
