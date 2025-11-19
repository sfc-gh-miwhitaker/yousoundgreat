/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 03_create_semantic_view.sql
 * PURPOSE: Create Snowflake native semantic view for Cortex Analyst integration.
 * 
 * OBJECTS CREATED:
 *   - SEMANTIC VIEW SFE_ANALYTICS_COSTS.SV_ACCOUNT_BILLING
 * 
 * RATIONALE:
 *   Cortex Analyst requires a SEMANTIC VIEW (not a raw table/view) to understand:
 *   - Column semantics (dimensions vs facts vs metrics)
 *   - Data types and descriptions
 *   - Synonyms for natural language queries
 *   - Primary keys for join optimization
 * 
 * SEMANTIC VIEW vs DYNAMIC TABLE:
 *   - DT_ACCOUNT_BILLING: Materialized data (fast queries)
 *   - SV_ACCOUNT_BILLING: Metadata layer on top of DT (AI understanding)
 *   - Agent uses SV, which queries DT under the hood
 * 
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

-- Create semantic view using YAML specification
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS',
  $$
name: SV_ACCOUNT_BILLING
description: Semantic view for account-level billing analytics, powering Cortex Analyst and Snowflake Intelligence agents
tables:
  - name: ACCOUNT_BILLING
    synonyms:
      - billing data
      - account costs
      - monthly billing
    description: Monthly billing aggregates per account with cost breakdowns and anomaly detection
    base_table:
      database: SNOWFLAKE_EXAMPLE
      schema: SFE_ANALYTICS_COSTS
      table: DT_ACCOUNT_BILLING
    primary_key:
      columns:
        - CUSTOMER_KEY
        - BILLING_MONTH
    
    dimensions:
      - name: ACCOUNT_ID
        synonyms:
          - account number
          - customer account
          - account identifier
        description: Unique account identifier for the customer
        expr: ACCOUNT_ID
        data_type: NUMBER(38,0)
      
      - name: CUSTOMER_NAME
        synonyms:
          - account name
          - customer name
          - account holder
        description: Name of the customer or account holder
        expr: CUSTOMER_NAME
        data_type: VARCHAR(16777216)
      
      - name: SEGMENT_NAME
        synonyms:
          - customer segment
          - account segment
          - tier
          - customer tier
        description: Customer segment classification (Enterprise, Commercial, SMB, Unassigned)
        expr: SEGMENT_NAME
        data_type: VARCHAR(16777216)
        is_enum: true
      
      - name: CUSTOMER_KEY
        description: Surrogate key for customer dimension (internal use)
        expr: CUSTOMER_KEY
        data_type: NUMBER(38,0)
      
      - name: LATEST_ALERT
        synonyms:
          - anomaly flag
          - alert status
          - anomaly status
        description: Latest anomaly alert status (ANOMALY or NORMAL)
        expr: LATEST_ALERT
        data_type: VARCHAR(16777216)
        is_enum: true
    
    time_dimensions:
      - name: BILLING_MONTH
        synonyms:
          - month
          - billing period
          - invoice month
          - billing date
        description: Month for which billing charges are aggregated (first day of month)
        expr: BILLING_MONTH
        data_type: DATE
        unique: false
      
      - name: LATEST_USAGE_TS
        synonyms:
          - last usage date
          - most recent usage
          - latest usage timestamp
        description: Timestamp of the most recent usage event in the billing month
        expr: LATEST_USAGE_TS
        data_type: TIMESTAMP_NTZ(9)
        unique: false
    
    facts:
      - name: VOICE_COST
        synonyms:
          - voice charges
          - voice spending
          - phone cost
        description: Total cost for voice services in the billing month
        expr: VOICE_COST
        data_type: NUMBER(38,4)
      
      - name: DATA_COST
        synonyms:
          - data charges
          - data spending
          - internet cost
        description: Total cost for data services in the billing month
        expr: DATA_COST
        data_type: NUMBER(38,4)
      
      - name: SMS_COST
        synonyms:
          - sms charges
          - text message cost
          - messaging cost
        description: Total cost for SMS services in the billing month
        expr: SMS_COST
        data_type: NUMBER(38,4)
      
      - name: TOTAL_COST
        synonyms:
          - total charges
          - total spending
          - invoice amount
          - bill amount
        description: Total cost across all services (voice + data + sms) for the billing month
        expr: TOTAL_COST
        data_type: NUMBER(38,4)
      
      - name: AVG_ANOMALY_SCORE
        synonyms:
          - anomaly score
          - variance score
        description: Average anomaly score (ratio of actual cost vs expected cost, >1.4 indicates anomaly)
        expr: AVG_ANOMALY_SCORE
        data_type: FLOAT
    
    metrics:
      - name: TOTAL_REVENUE
        synonyms:
          - revenue
          - total income
        description: Sum of all costs across accounts (equivalent to revenue for analysis)
        expr: SUM(TOTAL_COST)
      
      - name: AVERAGE_ACCOUNT_COST
        synonyms:
          - avg cost
          - average spending
          - mean cost
        description: Average cost per account
        expr: AVG(TOTAL_COST)
      
      - name: ACCOUNT_COUNT
        synonyms:
          - number of accounts
          - customer count
        description: Count of distinct accounts
        expr: COUNT(DISTINCT ACCOUNT_ID)
      
      - name: ANOMALY_COUNT
        synonyms:
          - number of anomalies
          - anomaly total
        description: Count of accounts with anomaly flags
        expr: SUM(IFF(LATEST_ALERT = 'ANOMALY', 1, 0))

filters:
  - name: CURRENT_MONTH
    synonyms:
      - this month
      - current billing period
    description: Filter to current month's billing data
    expr: BILLING_MONTH = DATE_TRUNC('month', CURRENT_DATE())
  
  - name: LAST_MONTH
    synonyms:
      - previous month
      - last billing period
    description: Filter to previous month's billing data
    expr: BILLING_MONTH = DATEADD('month', -1, DATE_TRUNC('month', CURRENT_DATE()))
  
  - name: ENTERPRISE_SEGMENT
    synonyms:
      - enterprise customers
      - enterprise accounts
    description: Filter to Enterprise segment only
    expr: SEGMENT_NAME = 'Enterprise'
  
  - name: HAS_ANOMALY
    synonyms:
      - with anomalies
      - flagged accounts
      - anomalous accounts
    description: Filter to accounts with anomaly alerts
    expr: LATEST_ALERT = 'ANOMALY'

verified_queries:
  - name: top_accounts_by_cost
    question: What were the top 5 accounts by cost in November 2024?
    verified_at: 1731974400
    verified_by: Michael Whitaker
    use_as_onboarding_question: true
    sql: |
      SELECT
        ACCOUNT_ID,
        CUSTOMER_NAME,
        SEGMENT_NAME,
        TOTAL_COST,
        VOICE_COST,
        DATA_COST,
        SMS_COST
      FROM ACCOUNT_BILLING
      WHERE BILLING_MONTH = '2024-11-01'
      ORDER BY TOTAL_COST DESC
      LIMIT 5
  
  - name: accounts_with_anomalies
    question: Show me all accounts with cost anomalies this month
    verified_at: 1731974400
    verified_by: Michael Whitaker
    use_as_onboarding_question: true
    sql: |
      SELECT
        ACCOUNT_ID,
        CUSTOMER_NAME,
        SEGMENT_NAME,
        BILLING_MONTH,
        TOTAL_COST,
        AVG_ANOMALY_SCORE,
        LATEST_ALERT
      FROM ACCOUNT_BILLING
      WHERE LATEST_ALERT = 'ANOMALY'
        AND BILLING_MONTH = DATE_TRUNC('month', CURRENT_DATE())
      ORDER BY AVG_ANOMALY_SCORE DESC
  
  - name: segment_comparison_3months
    question: Compare average costs between Enterprise, SMB, and Commercial segments over the last 3 months
    verified_at: 1731974400
    verified_by: Michael Whitaker
    sql: |
      SELECT
        SEGMENT_NAME,
        BILLING_MONTH,
        AVG(TOTAL_COST) AS avg_cost,
        COUNT(DISTINCT ACCOUNT_ID) AS account_count,
        SUM(TOTAL_COST) AS segment_total
      FROM ACCOUNT_BILLING
      WHERE BILLING_MONTH >= DATEADD('month', -3, DATE_TRUNC('month', CURRENT_DATE()))
      GROUP BY SEGMENT_NAME, BILLING_MONTH
      ORDER BY BILLING_MONTH DESC, avg_cost DESC
  
  - name: account_cost_breakdown
    question: What were the costs for account 12345 in October 2024?
    verified_at: 1731974400
    verified_by: Michael Whitaker
    use_as_onboarding_question: true
    sql: |
      SELECT
        ACCOUNT_ID,
        CUSTOMER_NAME,
        BILLING_MONTH,
        VOICE_COST,
        DATA_COST,
        SMS_COST,
        TOTAL_COST,
        ROUND((VOICE_COST / NULLIF(TOTAL_COST, 0)) * 100, 1) AS voice_pct,
        ROUND((DATA_COST / NULLIF(TOTAL_COST, 0)) * 100, 1) AS data_pct,
        ROUND((SMS_COST / NULLIF(TOTAL_COST, 0)) * 100, 1) AS sms_pct
      FROM ACCOUNT_BILLING
      WHERE ACCOUNT_ID = 12345
        AND BILLING_MONTH = '2024-10-01'
  
  - name: month_over_month_increases
    question: Which accounts had cost increases over 20% month-over-month?
    verified_at: 1731974400
    verified_by: Michael Whitaker
    sql: |
      WITH monthly_costs AS (
        SELECT
          ACCOUNT_ID,
          CUSTOMER_NAME,
          SEGMENT_NAME,
          BILLING_MONTH,
          TOTAL_COST,
          LAG(TOTAL_COST) OVER (PARTITION BY ACCOUNT_ID ORDER BY BILLING_MONTH) AS prev_month_cost
        FROM ACCOUNT_BILLING
      )
      SELECT
        ACCOUNT_ID,
        CUSTOMER_NAME,
        SEGMENT_NAME,
        BILLING_MONTH,
        prev_month_cost,
        TOTAL_COST AS current_month_cost,
        TOTAL_COST - prev_month_cost AS cost_change,
        ROUND(((TOTAL_COST - prev_month_cost) / NULLIF(prev_month_cost, 0)) * 100, 1) AS pct_change
      FROM monthly_costs
      WHERE prev_month_cost IS NOT NULL
        AND ((TOTAL_COST - prev_month_cost) / NULLIF(prev_month_cost, 0)) > 0.20
      ORDER BY pct_change DESC
  
  - name: enterprise_cost_trend
    question: Show me the cost trend for Enterprise accounts over the last 6 months
    verified_at: 1731974400
    verified_by: Michael Whitaker
    sql: |
      SELECT
        BILLING_MONTH,
        COUNT(DISTINCT ACCOUNT_ID) AS enterprise_account_count,
        SUM(TOTAL_COST) AS total_segment_cost,
        AVG(TOTAL_COST) AS avg_account_cost,
        MIN(TOTAL_COST) AS min_account_cost,
        MAX(TOTAL_COST) AS max_account_cost
      FROM ACCOUNT_BILLING
      WHERE SEGMENT_NAME = 'Enterprise'
        AND BILLING_MONTH >= DATEADD('month', -6, DATE_TRUNC('month', CURRENT_DATE()))
      GROUP BY BILLING_MONTH
      ORDER BY BILLING_MONTH DESC
  $$
);

-- Verify semantic view was created successfully
SELECT 'Semantic view SV_ACCOUNT_BILLING created successfully' AS status;

-- Grant usage to roles that will query through Cortex Analyst
GRANT SELECT ON SEMANTIC VIEW SFE_ANALYTICS_COSTS.SV_ACCOUNT_BILLING TO ROLE SYSADMIN;
GRANT SELECT ON SEMANTIC VIEW SFE_ANALYTICS_COSTS.SV_ACCOUNT_BILLING TO ROLE PUBLIC;

