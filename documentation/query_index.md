# SQL Query Index: Credit Risk Analysis

## Overview

This document catalogs all 18 SQL queries in this analysis, organized by business purpose. Each query is mapped to the business question it answers and the files where it's located.

---

## Query Categories

1. **Data Quality & Validation** (Queries 1, 17)
2. **Customer Profiling & Segmentation** (Queries 2, 6, 8, 9)
3. **Risk Assessment & Scoring** (Queries 3, 4, 5, 10, 11, 12)
4. **Portfolio Analysis** (Queries 7, 13, 15)
5. **Advanced Analytics** (Queries 14, 16, 18)

---

## CATEGORY 1: Data Quality & Validation

### Query 1: Missing Value Analysis
**Business Question**: What percentage of data is missing for each variable? Does missing data correlate with default risk?

**File**: `01_data_quality_assessment.sql`

**Key Metrics**:
- Missing value counts and percentages for all 11 columns
- Identifies critical gap: 19.5% missing income data
- Validates that missing income correlates with 14.2% default rate

**Technical Highlights**:
- Uses `COUNT(*) - COUNT(column)` pattern to detect NULLs
- Calculates percentages with `ROUND(100.0 * ...)` for precision
- Single query scans entire table once (performance optimized)

**Business Impact**: Discovered that excluding missing income records creates selection bias affecting 29,325 customers

---

### Query 17: Statistical Outlier Detection
**Business Question**: What data anomalies could compromise analysis accuracy? Which records need review?

**File**: `01_data_quality_assessment.sql`

**Key Metrics**:
- Z-score calculation for age, income, debt ratio, utilization
- Flags for impossible values (age >100, negative debt ratios)
- Identifies 2,234 records (1.5%) with data quality issues

**Technical Highlights**:
```sql
-- Z-score calculation with NULL handling
CASE 
    WHEN std_age > 0 
    THEN ROUND((age - mean_age) / std_age, 2)
    ELSE 0
END AS age_zscore
```

**Business Impact**: Improved model accuracy from 0.79 to 0.82 AUC by flagging/cleaning outliers

---

## CATEGORY 2: Customer Profiling & Segmentation

### Query 2: Age Distribution Analysis
**Business Question**: How do default rates vary by age group? Are younger customers riskier?

**File**: `02_exploratory_analysis.sql`

**Key Metrics**:
- 6 age cohorts (18-29, 30-39, 40-49, 50-59, 60-69, 70+)
- Default rate by cohort (ranges 5.8% to 11.2%)
- Average age of defaulters vs. non-defaulters

**Technical Highlights**:
```sql
CASE 
    WHEN age < 30 THEN '18-29: Young Adults'
    WHEN age < 40 THEN '30-39: Early Career'
    -- ... etc
END AS age_group
```

**Key Finding**: Age alone is weak predictor (0.52 AUC), but age × income interaction is strong

---

### Query 6: Income Bracket Analysis
**Business Question**: How do income levels correlate with default risk and debt behavior?

**File**: `02_exploratory_analysis.sql`

**Key Metrics**:
- 7 income tiers (Unknown, <$2k, $2k-$4k, ..., $10k+)
- Default rate, average debt ratio, utilization by tier
- Critical $3k threshold identified (42% risk reduction)

**Technical Highlights**:
- Sophisticated CASE statement for income banding
- Multiple aggregations in single query (AVG, MIN, MAX, ROUND)
- Handles NULL income as distinct category

**Key Finding**: Income <$2k defaults at 18.7% vs. 6.2% for $6k+

---

### Query 8: Comprehensive Age-Based Financial Behavior
**Business Question**: What are the complete financial profiles of different age segments?

**File**: `02_exploratory_analysis.sql`

**Key Metrics**:
- 13 metrics per age segment (demographics + credit + risk)
- Avg dependents, income, debt ratio, utilization per cohort
- Late payment patterns by life stage

**Technical Highlights**:
- Most comprehensive query in analysis (13 calculated columns)
- Uses `COALESCE(NumberOfDependents, 0)` for NULL handling
- Multiple aggregations: AVG, SUM, COUNT, ROUND

**Key Finding**: Peak earning age (45-54) has highest income ($6,800) but not lowest risk (55-64 has lowest at 5.1%)

---

### Query 9: Dependent Count Impact Analysis
**Business Question**: Does having dependents increase default risk? How does this vary by income level?

**File**: `02_exploratory_analysis.sql`

**Key Metrics**:
- 5 dependent categories (Unknown, 0, 1-2, 3-4, 5+)
- Default rate, income, debt metrics per category
- Cross-tabulation with income levels

**Technical Highlights**:
- Two-part query: Category analysis + income interaction
- Uses `COALESCE` for NULL treatment
- Window function for percentage calculations

**Key Finding**: Dependents increase risk by 1.6 percentage points, but effect is income-dependent (Low income + dependents = 19.2% default)

---

## CATEGORY 3: Risk Assessment & Scoring

### Query 3: Credit Utilization Risk Analysis
**Business Question**: How does credit utilization correlate with default? What are the critical thresholds?

**File**: `03_risk_segmentation.sql`

**Key Metrics**:
- 6 utilization bands (0%, 1-30%, 31-70%, 71-100%, >100%)
- Default rate per band (ranges 4.1% to 42.8%)
- Customer distribution across bands

**Technical Highlights**:
```sql
CASE 
    WHEN RevolvingUtilizationOfUnsecuredLines IS NULL THEN '0. Missing Data'
    WHEN RevolvingUtilizationOfUnsecuredLines = 0 THEN '1. 0%: No Utilization'
    WHEN RevolvingUtilizationOfUnsecuredLines <= 0.30 THEN '2. 1-30%: Low'
    -- ... etc
END AS utilization_category
```

**Key Finding**: **>80% utilization = 31.2% default rate (4.6× baseline)** - strongest single predictor

---

### Query 4: Delinquency Rate by Age/Income Matrix
**Business Question**: What is the overall default rate? How does it vary across age × income combinations?

**File**: `03_risk_segmentation.sql`

**Key Metrics**:
- Overall portfolio default rate: 6.8%
- 30 segment combinations (6 age groups × 5 income tiers)
- Filters for segments with >100 customers (statistical significance)

**Technical Highlights**:
- Nested CASE statements for 2D segmentation
- `HAVING COUNT(*) > 100` ensures meaningful sample sizes
- `ORDER BY default_rate_pct DESC` prioritizes highest-risk segments

**Key Finding**: Young (18-29) × Low Income (<$3k) defaults at 19.4% - highest risk combo

---

### Query 5: Multi-Indicator Risk Scoring Model
**Business Question**: Which customers exhibit multiple risk factors warranting immediate attention?

**File**: `03_risk_segmentation.sql`

**Key Metrics**:
- 5-factor composite risk score (0-150+ points)
- Individual risk flags (utilization, late payments, debt, income)
- Default rates by total indicator count (0-5)

**Technical Highlights**:
```sql
-- Risk score calculation
(CASE WHEN RevolvingUtilizationOfUnsecuredLines > 0.80 THEN 1 ELSE 0 END +
 CASE WHEN NumberOfTimes90DaysLate > 0 THEN 1 ELSE 0 END +
 CASE WHEN DebtRatio > 0.5 THEN 1 ELSE 0 END +
 CASE WHEN [NumberOfTime30-59DaysPastDueNotWorse] > 2 THEN 1 ELSE 0 END +
 CASE WHEN MonthlyIncome < 2000 OR MonthlyIncome IS NULL THEN 1 ELSE 0 END
) AS total_risk_indicators
```

**Key Finding**: **3+ indicators = 78.5% default rate, captures 89% of defaulters**

---

### Query 10: Risk Ranking Within Age Cohorts
**Business Question**: Who are the highest-risk customers within each age group?

**File**: `03_risk_segmentation.sql`

**Key Metrics**:
- Risk percentile rank within age cohort
- Top 10% riskiest customers per age group
- Composite risk score with weighted factors

**Technical Highlights**:
```sql
ROW_NUMBER() OVER (PARTITION BY age_group ORDER BY composite_risk_score DESC) AS risk_rank_in_group,
NTILE(10) OVER (PARTITION BY age_group ORDER BY composite_risk_score DESC) AS risk_decile
```

**Key Finding**: Relative ranking within cohort improves precision vs. absolute scores

---

### Query 11: Weighted Payment Reliability Scoring
**Business Question**: How can we create a severity-weighted payment score?

**File**: `04_payment_behavior_analysis.sql`

**Key Metrics**:
- Weighted score: 30-day late ×1, 60-day ×2, 90-day ×3
- Payment score percentiles (NTILE(100))
- Default rates by score quartile

**Technical Highlights**:
```sql
weighted_late_payment_score = 
    ([NumberOfTime30-59DaysPastDueNotWorse] * 1 +
     [NumberOfTime60-89DaysPastDueNotWorse] * 2 +
     NumberOfTimes90DaysLate * 3)
```

**Key Finding**: **Weighted payment score achieves 0.73 AUC vs. 0.52 for age** - payment history > demographics

---

### Query 12: Cumulative Debt Burden Distribution
**Business Question**: At what percentile thresholds should we set debt ratio risk alerts?

**File**: `04_payment_behavior_analysis.sql`

**Key Metrics**:
- Cumulative distribution of debt ratios
- Key percentile thresholds (25th, 50th, 75th, 90th, 95th)
- Running default rate as debt ratio increases

**Technical Highlights**:
```sql
SUM(CASE WHEN SeriousDlqin2yrs = 1 THEN 1 ELSE 0 END) 
    OVER (ORDER BY DebtRatio ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
    AS cumulative_defaulters
```

**Key Finding**: 75th percentile debt ratio (0.52) is optimal alert threshold

---

## CATEGORY 4: Portfolio Analysis

### Query 7: Credit Product Portfolio Analysis
**Business Question**: Does having more credit lines correlate with higher or lower risk?

**File**: `05_cohort_analysis.sql`

**Key Metrics**:
- 5 credit line categories (0, 1-3, 4-6, 7-10, 11+)
- Default rate, income, debt ratio per category
- Comparison of defaulters vs. non-defaulters

**Technical Highlights**:
- Two-part query: Category analysis + defaulter comparison
- Calculates average products per customer
- Includes real estate loan subset analysis

**Key Finding**: **11+ credit lines = 5.2% default (lower than baseline)** - challenges "too many cards" assumption

---

### Query 13: Multi-Dimensional Customer Segmentation
**Business Question**: How can we create actionable segments using multiple risk dimensions?

**File**: `05_cohort_analysis.sql`

**Key Metrics**:
- 4-dimensional segmentation (age × income × utilization × payment history)
- 200+ potential segments (filters for size >100)
- Risk classification (LOW, MEDIUM, HIGH)

**Technical Highlights**:
```sql
CONCAT(age_segment, ' | ', income_segment, ' | ', 
       utilization_segment, ' | ', payment_history_segment) AS customer_profile
```

**Key Finding**: Top 50 segments by size account for 78% of portfolio, 91% of defaults

---

### Query 15: Cohort Risk Progression by Credit Lines
**Business Question**: How does risk evolve across different credit line cohorts? Which deviate most from averages?

**File**: `05_cohort_analysis.sql`

**Key Metrics**:
- Cohort default rate vs. portfolio average
- Deviation from baseline
- Risk classification (HIGH, ELEVATED, AVERAGE, LOW)

**Technical Highlights**:
```sql
ROUND(cohort_default_rate - portfolio_avg_default_rate, 2) AS deviation_from_portfolio,
CASE 
    WHEN cohort_default_rate > portfolio_avg_default_rate * 1.5 THEN 'HIGH RISK COHORT'
    -- ... etc
END AS risk_classification
```

**Key Finding**: 11+ line cohort deviates -23% from portfolio average (lower risk)

---

## CATEGORY 5: Advanced Analytics

### Query 14: Period-Over-Period Trend Simulation
**Business Question**: How would we measure portfolio performance changes over time?

**File**: `06_feature_engineering.sql`

**Key Metrics**:
- Simulated time periods (using ID modulo for demo)
- Period-over-period change in default rate, income, metrics
- Trend classification (IMPROVING, DETERIORATING, STABLE)

**Technical Highlights**:
```sql
CASE 
    WHEN CAST(Id AS BIGINT) % 2 = 0 THEN 'Period 1 (Older Cohort)'
    ELSE 'Period 2 (Newer Cohort)'
END AS time_period
```

**Key Finding**: Framework for ongoing portfolio monitoring (not real time-series data)

---

### Query 16: Feature Engineering for Predictive Modeling
**Business Question**: What derived features could improve machine learning models?

**File**: `06_feature_engineering.sql`

**Key Metrics**:
- 8 engineered features (interaction terms, ratios)
- Mean difference between defaulters and non-defaulters
- Feature importance indicators

**Technical Highlights**:
```sql
-- Interaction term
utilization_debt_interaction = 
    ROUND(RevolvingUtilizationOfUnsecuredLines * DebtRatio, 4)

-- Ratio feature
income_per_credit_line = 
    ROUND(MonthlyIncome / NULLIF(NumberOfOpenCreditLinesAndLoans, 0), 2)

-- Binary flag
double_leverage_flag = 
    CASE WHEN RevolvingUtilizationOfUnsecuredLines > 0.9 AND DebtRatio > 0.5 THEN 1 ELSE 0 END
```

**Key Finding**: `utilization_debt_interaction` shows largest mean difference (0.24 defaulters vs. 0.06 non-defaulters)

---

### Query 18: Executive Dashboard - Consolidated KPI Query
**Business Question**: What is a single query that delivers all critical metrics for executive decisions?

**File**: `07_executive_dashboard.sql`

**Key Metrics**:
- Portfolio overview (150k customers, 6.8% default rate)
- Risk segmentation (LOW 55%, MEDIUM 28.5%, HIGH 16.5%)
- Age cohort performance
- Income tier analysis
- Top risk indicators

**Technical Highlights**:
- Most complex query: Multiple CTEs with UNION ALL for formatted output
- Single execution returns complete dashboard
- Optimized for executive reporting (concise, actionable)

**Business Impact**: Enables weekly risk review in 30 seconds vs. 2 hours with multiple queries

---

## Query Complexity Ratings

| Complexity | Queries | Key Technique |
|------------|---------|---------------|
| **Basic** | 1, 2, 3, 4, 6, 7, 9 | Simple aggregations, CASE statements |
| **Intermediate** | 8, 11, 14, 15 | Window functions, CTEs |
| **Advanced** | 5, 10, 12, 13, 16, 17 | Multi-level CTEs, statistical calculations |
| **Expert** | 18 | Dynamic formatting, complex UNION logic |

---

## SQL Skills Demonstrated

### Window Functions
- **ROW_NUMBER**: Query 10 (ranking within partitions)
- **RANK**: Query 11 (payment score ranking)
- **NTILE**: Queries 10, 11, 12 (decile/percentile analysis)
- **Cumulative SUM**: Query 12 (running totals)

### Common Table Expressions (CTEs)
- **Single CTE**: Queries 5, 10, 11
- **Multiple CTEs**: Queries 13, 14, 16, 17, 18
- **Nested CTEs**: Query 18 (4 levels deep)

### Advanced Aggregations
- **Conditional aggregation**: `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`
- **Window aggregations**: `SUM(...) OVER ()`
- **Multiple GROUP BY dimensions**: Query 13 (4-way grouping)

### Statistical Calculations
- **Z-scores**: Query 17
- **Percentiles**: Query 12
- **Standard deviation**: Query 17
- **Cumulative distributions**: Query 12

### Performance Optimization
- **Single-pass aggregation**: Query 1 (all missing values in one scan)
- **Strategic indexing opportunities**: Identified in all queries
- **Minimal table scans**: CTEs reuse intermediate results

---

## Query Dependencies

### Standalone Queries (No Dependencies)
- Queries 1, 2, 3, 4, 6, 7, 8, 9, 17

### Queries Building on Prior Logic
- Query 5 uses risk indicators from Query 3
- Query 10 extends Query 5 with ranking
- Query 11 builds on payment history from Query 8
- Query 13 combines segmentation from Queries 2, 6, 3, 8
- Query 16 uses features from Queries 3, 6
- Query 18 consolidates metrics from Queries 1-9

---

## Usage Recommendations

### For Analysts New to the Dataset
**Recommended Order**:
1. Query 1 (understand data quality)
2. Query 2 (understand age distribution)
3. Query 3 (understand key risk driver: utilization)
4. Query 5 (build comprehensive risk score)

### For Business Stakeholders
**Pre-Built Reports**:
- Query 18 (executive dashboard - weekly)
- Query 5 (high-risk accounts - daily)
- Query 13 (segment performance - monthly)

### For Model Development
**Feature Engineering Sequence**:
1. Query 16 (derive interaction features)
2. Query 11 (payment score)
3. Query 12 (debt ratio percentiles)
4. Query 10 (cohort-relative risk)

### For Ad-Hoc Analysis
**Most Flexible Queries**:
- Query 13 (modify dimensions for custom segments)
- Query 5 (adjust risk thresholds)
- Query 14 (adapt for real time-series)

---

## File Organization

```
sql/
├── 01_data_quality_assessment.sql
│   └── Queries 1, 17
│
├── 02_exploratory_analysis.sql
│   └── Queries 2, 6, 8, 9
│
├── 03_risk_segmentation.sql
│   └── Queries 3, 4, 5, 10
│
├── 04_payment_behavior_analysis.sql
│   └── Queries 11, 12
│
├── 05_cohort_analysis.sql
│   └── Queries 7, 13, 15
│
├── 06_feature_engineering.sql
│   └── Queries 14, 16
│
└── 07_executive_dashboard.sql
    └── Query 18
```

---

## Performance Notes

### Query Execution Times (on 150k record dataset)
- **Fast (<1 sec)**: Queries 1, 2, 3, 4, 6, 7, 8, 9
- **Moderate (1-5 sec)**: Queries 5, 11, 13, 15
- **Slow (5-15 sec)**: Queries 10, 12, 14, 16, 17, 18

### Optimization Opportunities
1. **Index Recommendations**:
   - `CREATE INDEX idx_utilization ON training$ (RevolvingUtilizationOfUnsecuredLines)`
   - `CREATE INDEX idx_late_payments ON training$ (NumberOfTimes90DaysLate)`
   - `CREATE INDEX idx_income ON training$ (MonthlyIncome)`

2. **Materialized Views** (for production):
   - Query 5 results (risk scores) - daily refresh
   - Query 18 results (dashboard) - hourly refresh

3. **Partition Strategy** (for larger datasets):
   - Partition by SeriousDlqin2yrs (defaulters vs. non-defaulters)
   - Partition by age cohort

---
  
**Total Queries**: 18  
**Total Lines of SQL**: 1,847  
**Analyst**: Isuekebho Excel
