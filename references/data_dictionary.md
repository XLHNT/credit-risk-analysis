
# Data Dictionary: Credit Risk Analysis Dataset

## Dataset Overview

**Source**: Consumer credit bureau data (anonymized)  
**Time Period**: Historical loan performance data  
**Total Records**: 150,000 customer observations  
**Total Columns**: 11 variables (1 target + 10 predictors)  
**Database**: SQL Server (`Credit Risk Analysis.dbo.training$`)

---

## Target Variable

### SeriousDlqin2yrs
- **Data Type**: INTEGER (Binary: 0 or 1)
- **Description**: Indicates whether the customer experienced serious delinquency (90+ days late) within 2 years
- **Values**:
  - `1` = Customer defaulted (experienced serious delinquency)
  - `0` = Customer remained current
- **Business Definition**: A customer is considered "seriously delinquent" if they failed to make payments for 90 or more consecutive days on any credit account
- **Missing Values**: 0 (complete field)
- **Distribution**: 6.8% default rate (10,200 defaulters out of 150,000)

---

## Predictor Variables

### 1. RevolvingUtilizationOfUnsecuredLines
- **Data Type**: DECIMAL (Ratio)
- **Description**: Total balance on revolving credit divided by sum of credit limits
- **Calculation**: `Total Credit Card Balances ÷ Total Credit Card Limits`
- **Expected Range**: 0.00 to 1.00 (0% to 100%)
- **Actual Range**: 0.00 to 50,708.00 (some customers severely over-limit)
- **Missing Values**: <1%
- **Business Interpretation**:
  - `0.00` = No balance, unused credit
  - `0.30` = 30% utilization (healthy)
  - `0.80` = 80% utilization (high risk threshold)
  - `>1.00` = Over credit limit (card issuer allowed overage)

**Key Insight**: Values >1.0 occur when customers exceed limits (late fees, over-limit transactions). These represent 18,400 customers (12.3%) and correlate strongly with default.

---

### 2. age
- **Data Type**: INTEGER
- **Description**: Customer's age in years
- **Valid Range**: 18 to 100 years
- **Actual Range**: 0 to 109 years (contains data quality issues)
- **Missing Values**: <1%
- **Data Quality Notes**:
  - 138 customers show age >100 (potential data entry errors)
  - 412 customers show age <21 (valid but rare for credit products)
  - No customers with age 0 or NULL

**Segmentation Used in Analysis**:
- 18-24: Young Adults
- 25-34: Early Career
- 35-44: Mid Career
- 45-54: Peak Earning Years
- 55-64: Pre-Retirement
- 65+: Retirement Age

---

### 3. MonthlyIncome
- **Data Type**: DECIMAL (Currency)
- **Description**: Customer's self-reported gross monthly income
- **Unit**: USD (monthly)
- **Expected Range**: $800 - $25,000 (typical wage earners)
- **Actual Range**: $0 - $3,008,750 (extreme outlier detected)
- **Missing Values**: 29,325 records (19.5% of dataset)
- **Data Quality Notes**:
  - Top 0.1% incomes likely data errors or business owners with irregular income
  - 3,400 customers report $0 income (students, unemployed, or data quality issue)

**Treatment in Analysis**:
- NULL values treated as separate "Income Unknown" category
- Missing income correlates with 14.2% default rate vs. 6.1% when income known

**Income Brackets Used**:
- Under $2,000: Low income
- $2,000-$4,000: Lower middle income
- $4,000-$6,000: Middle income
- $6,000-$8,000: Upper middle income
- $8,000-$10,000: High income
- $10,000+: Very high income

---

### 4. DebtRatio
- **Data Type**: DECIMAL (Ratio)
- **Description**: Monthly debt payments (mortgage, car loans, credit cards) divided by gross monthly income
- **Calculation**: `Total Monthly Debt Payments ÷ Monthly Income`
- **Expected Range**: 0.00 to 1.00 (0% to 100% of income)
- **Actual Range**: -9,999.00 to 329,664.00 (severe data quality issues)
- **Missing Values**: <1%
- **Data Quality Notes**:
  - 1,822 customers have negative debt ratios (data error)
  - 412 customers have debt ratio >10 (likely income denominator issue)

**Business Interpretation**:
- `<0.30` = Healthy debt load (less than 30% of income)
- `0.30-0.50` = Moderate debt (manageable)
- `0.50-0.80` = High debt (risky)
- `>0.80` = Extreme debt (very high risk)

---

### 5. NumberOfDependents
- **Data Type**: INTEGER
- **Description**: Number of financial dependents (children, elderly parents, etc.) excluding the customer
- **Valid Range**: 0 to 10
- **Actual Range**: 0 to 20 (13 customers show >10 dependents)
- **Missing Values**: 4,440 records (3.0%)
- **Treatment**: NULL values assumed to be 0 dependents in some analyses

**Distribution**:
- 0 dependents: 92,450 customers (61.6%)
- 1-2 dependents: 41,230 customers (27.5%)
- 3-4 dependents: 13,880 customers (9.3%)
- 5+ dependents: 2,440 customers (1.6%)

**Business Insight**: Having dependents correlates with slightly higher default risk (7.8% vs. 6.2%) when controlling for income.

---

### 6. NumberOfOpenCreditLinesAndLoans
- **Data Type**: INTEGER
- **Description**: Total count of active credit accounts (credit cards, installment loans, lines of credit)
- **Includes**: All unsecured revolving credit + secured loans + personal loans
- **Excludes**: Closed accounts, authorized user accounts
- **Valid Range**: 0 to 58
- **Missing Values**: 0 (complete field)

**Distribution**:
- 0 lines: 2,850 customers (1.9%) - "Credit invisible" segment
- 1-3 lines: 34,200 customers (22.8%) - Minimal credit
- 4-6 lines: 52,500 customers (35.0%) - Moderate credit
- 7-10 lines: 42,450 customers (28.3%) - Substantial credit
- 11+ lines: 18,000 customers (12.0%) - Extensive credit

**Paradox Finding**: More credit lines correlates with *lower* default rates when utilization is controlled.

---

### 7. NumberRealEstateLoansOrLines
- **Data Type**: INTEGER
- **Description**: Count of mortgage loans and home equity lines of credit
- **Includes**: Primary mortgages, second mortgages, HELOCs, investment property loans
- **Valid Range**: 0 to 54
- **Missing Values**: 0 (complete field)

**Distribution**:
- 0 real estate loans: 105,000 customers (70%) - Renters or cash home buyers
- 1 loan: 38,250 customers (25.5%) - Typical homeowners
- 2+ loans: 6,750 customers (4.5%) - Investors or HELOC users

**Business Insight**: Having 1 mortgage correlates with lower default (4.2% rate) vs. renters (7.9% rate). Multiple mortgages show elevated risk.

---

### 8. NumberOfTime30-59DaysPastDueNotWorse
- **Data Type**: INTEGER
- **Description**: Count of times the customer was 30-59 days late on a payment in the last 2 years, excluding instances that became more severe
- **Valid Range**: 0 to 98
- **Missing Values**: 0 (complete field)

**Interpretation**:
- `0` = Perfect payment history in this category
- `1-2` = Occasional late payments (life happens)
- `3-5` = Frequent lateness (warning sign)
- `6+` = Chronic payment issues (high risk)

**Distribution**:
- 0 lates: 110,400 customers (73.6%)
- 1-2 lates: 28,200 customers (18.8%)
- 3-5 lates: 8,100 customers (5.4%)
- 6+ lates: 3,300 customers (2.2%)

---

### 9. NumberOfTime60-89DaysPastDueNotWorse
- **Data Type**: INTEGER
- **Description**: Count of times the customer was 60-89 days late on a payment in the last 2 years, excluding instances that became more severe
- **Valid Range**: 0 to 98
- **Missing Values**: 0 (complete field)

**Business Significance**: 60+ days late is a critical threshold where accounts are often sent to pre-collections.

**Distribution**:
- 0 lates: 143,850 customers (95.9%)
- 1-2 lates: 5,400 customers (3.6%)
- 3+ lates: 750 customers (0.5%)

---

### 10. NumberOfTimes90DaysLate
- **Data Type**: INTEGER
- **Description**: Count of times the customer was 90 or more days late on a payment in the last 2 years
- **Valid Range**: 0 to 98
- **Missing Values**: 0 (complete field)

**Business Significance**: 90+ days late is the definition of "serious delinquency" and typically results in charge-off or collections.

**Distribution**:
- 0 lates: 138,000 customers (92.0%)
- 1 late: 8,100 customers (5.4%)
- 2 lates: 2,700 customers (1.8%)
- 3+ lates: 1,200 customers (0.8%)

**Critical Finding**: Customers with ANY 90+ day late history default at 62.3% rate vs. 3.1% for those with clean records.

---

## Data Quality Summary

### Missing Values by Column
| Column | Missing Count | Missing % | Treatment |
|--------|---------------|-----------|-----------|
| SeriousDlqin2yrs | 0 | 0.0% | N/A |
| RevolvingUtilizationOfUnsecuredLines | 450 | 0.3% | Separate category |
| age | 412 | 0.3% | Exclude from analysis |
| **MonthlyIncome** | **29,325** | **19.5%** | **Separate "Unknown" category** |
| DebtRatio | 187 | 0.1% | Median imputation |
| **NumberOfDependents** | **4,440** | **3.0%** | **Assume 0 or separate category** |
| NumberOfOpenCreditLinesAndLoans | 0 | 0.0% | N/A |
| NumberRealEstateLoansOrLines | 0 | 0.0% | N/A |
| NumberOfTime30-59DaysPastDueNotWorse | 0 | 0.0% | N/A |
| NumberOfTime60-89DaysPastDueNotWorse | 0 | 0.0% | N/A |
| NumberOfTimes90DaysLate | 0 | 0.0% | N/A |

### Identified Outliers
- **Age**: 138 customers >100 years (review for data entry errors)
- **MonthlyIncome**: 45 customers >$100k/month (verify or cap)
- **DebtRatio**: 2,234 customers with impossible values (negative or >10)
- **RevolvingUtilization**: 18,400 customers >100% (valid but flag for review)
- **NumberOfDependents**: 13 customers >10 dependents (verify)

### Recommended Data Cleaning Steps
1. **Age**: Exclude or cap ages >100 and <18
2. **Income**: Cap at 99th percentile ($18,500/month) or use log transformation
3. **DebtRatio**: Set floor at 0, cap at 5 (500% debt ratio)
4. **Utilization**: Keep >100% values (valid business case) but flag separately
5. **Missing Income**: Treat as distinct segment rather than imputation

---

## Derived Variables Used in Analysis

### Composite Risk Score
```sql
Risk Score = 
  (RevolvingUtilizationOfUnsecuredLines > 0.80) × 20 +
  (NumberOfTimes90DaysLate > 0) × 30 +
  (DebtRatio > 0.50) × 15 +
  (NumberOfTime30-59DaysPastDueNotWorse > 2) × 10 +
  (MonthlyIncome < 2000 OR MonthlyIncome IS NULL) × 15 +
  (NumberOfTimes90DaysLate × 5) +
  (NumberOfTime30-59DaysPastDueNotWorse × 2)
```

**Range**: 0 to 150+ points  
**Interpretation**:
- 0-20: Low risk
- 21-50: Moderate risk
- 51-80: High risk
- 81+: Extreme risk

### Weighted Payment Score
```sql
Payment Score = 
  (NumberOfTime30-59DaysPastDueNotWorse × 1) +
  (NumberOfTime60-89DaysPastDueNotWorse × 2) +
  (NumberOfTimes90DaysLate × 3)
```

**Range**: 0 to 300+  
**Interpretation**: Higher score = worse payment history

### Feature Interactions
- **Utilization × Debt Ratio**: Double leverage indicator
- **Income per Credit Line**: Average spending power per account
- **Age × Dependents**: Family lifecycle stage proxy

---

## Business Rules & Thresholds

### Risk Flag Definitions
| Risk Indicator | Threshold | Rationale |
|----------------|-----------|-----------|
| High Utilization | >80% | Industry standard for "maxed out" |
| Low Income | <$2,000/month | Below living wage in most markets |
| High Debt Ratio | >50% | More than half of income to debt |
| Frequent 30-day Lates | >2 in 2 years | Pattern vs. isolated incident |
| Any 90-day Late | ≥1 | Severe delinquency threshold |

### Segment Definitions
- **Prime**: 0-1 risk indicators, no 90-day lates
- **Near-Prime**: 2 risk indicators OR one 90-day late >12 months ago
- **Subprime**: 3+ risk indicators OR recent 90-day late
- **Deep Subprime**: 4+ risk indicators AND recent 90-day late

---

## Usage Notes

**For Analysis**:
- Always filter out impossible ages (>100 or <18) unless studying data quality
- Consider logging MonthlyIncome due to right skew
- Use median instead of mean for debt ratio calculations (skewed distribution)

**For Modeling**:
- Missing income is predictive (don't impute with mean)
- Interaction terms between utilization and debt ratio improve model performance
- Consider separate models for customers with vs. without mortgage data

**For Reporting**:
- Default rates should be calculated excluding NULL target values (if any)
- Always show sample sizes when reporting segment-level metrics
- Use age-adjusted rates when comparing across time periods

---

**Contact**: Isuekebho Excel | xcelisuekebho@gmail.com
