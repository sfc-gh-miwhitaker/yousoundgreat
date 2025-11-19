/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 02_create_views.sql
 * PURPOSE: Define curated views + dynamic tables for analytics and AI.
 * OBJECTS CREATED:
 *   - VIEW SFE_STG_TELECOM.V_USAGE_ENRICHED
 *   - DYNAMIC TABLE SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE VIEW SFE_STG_TELECOM.V_USAGE_ENRICHED AS
WITH base_usage AS (
    SELECT
        um.usage_id,
        um.account_id,
        um.usage_ts,
        um.minutes_used,
        um.data_mb,
        um.sms_count,
        um.service_type,
        um.cost_amount,
        um.region_code,
        seg.segment_name,
        seg.lifecycle_status,
        alloc.cost_bucket,
        alloc.bucket_amount,
        AVG(um.cost_amount) OVER (PARTITION BY um.account_id) AS avg_account_cost
    FROM SFE_RAW_BILLING.USAGE_METRICS AS um
    LEFT JOIN SFE_RAW_BILLING.CUSTOMER_SEGMENTS AS seg
        ON um.account_id = seg.account_id
    LEFT JOIN SFE_RAW_BILLING.COST_ALLOCATIONS AS alloc
        ON um.usage_id = alloc.usage_id
)
SELECT
    usage_id,
    account_id,
    usage_ts,
    minutes_used,
    data_mb,
    sms_count,
    service_type,
    cost_amount AS total_cost,
    region_code,
    COALESCE(segment_name, 'Unassigned') AS segment_name,
    lifecycle_status,
    COALESCE(cost_bucket, service_type) AS cost_bucket,
    COALESCE(bucket_amount, cost_amount) AS bucket_amount,
    CASE
        WHEN cost_amount > avg_account_cost * 1.4 THEN 'ANOMALY'
        ELSE 'NORMAL'
    END AS anomaly_flag,
    ROUND(cost_amount / NULLIF(avg_account_cost, 0), 4) AS anomaly_score,
    CURRENT_TIMESTAMP() AS calculated_at
FROM base_usage;

CREATE OR REPLACE DYNAMIC TABLE SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
    TARGET_LAG = '15 minutes'
    WAREHOUSE = SFE_BILLING_WH
    COMMENT = 'DEMO: Account-level billing aggregates powering Snowflake Intelligence'
AS
SELECT
    dim.customer_key,
    dim.account_id,
    dim.customer_name,
    dim.segment_name,
    DATE_TRUNC('month', stg.usage_ts) AS billing_month,
    SUM(IFF(stg.service_type = 'voice', stg.total_cost, 0)) AS voice_cost,
    SUM(IFF(stg.service_type = 'data', stg.total_cost, 0)) AS data_cost,
    SUM(IFF(stg.service_type = 'sms', stg.total_cost, 0)) AS sms_cost,
    SUM(stg.total_cost) AS total_cost,
    AVG(stg.anomaly_score) AS avg_anomaly_score,
    MAX(stg.anomaly_flag) AS latest_alert,
    MAX(stg.usage_ts) AS latest_usage_ts
FROM SFE_STG_TELECOM.V_USAGE_ENRICHED AS stg
JOIN SFE_ANALYTICS_COSTS.DIM_CUSTOMER AS dim
    ON stg.account_id = dim.account_id
GROUP BY
    dim.customer_key,
    dim.account_id,
    dim.customer_name,
    dim.segment_name,
    DATE_TRUNC('month', stg.usage_ts);

/*******************************************************************************
 * VALIDATED EXAMPLE QUERIES
 * 
 * Purpose: Pre-validated queries that demonstrate correct semantic view usage.
 * These serve as:
 * 1. Unit tests for semantic view correctness
 * 2. Example patterns for Cortex Analyst SQL generation
 * 3. Documentation of intended use cases
 * 4. Training examples for Snowflake Intelligence agents
 * 
 * Validation: Each query MUST execute successfully and return expected results.
 * Maintenance: Update when semantic views change; re-validate quarterly.
 * Agent Integration: Copy these into agent instructions as example interactions.
 ******************************************************************************/

-- Example 1: Top accounts by total cost in a specific month
-- Use case: "What were the top 5 accounts by cost in November 2024?"
-- Expected: 5 rows with account details, costs, ordered DESC by total_cost
SELECT
    account_id,
    customer_name,
    segment_name,
    total_cost,
    voice_cost,
    data_cost,
    sms_cost
FROM SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
WHERE billing_month = '2024-11-01'
ORDER BY total_cost DESC
LIMIT 5;

-- Example 2: Accounts with anomalies in current month
-- Use case: "Show me all accounts with cost anomalies this month"
-- Expected: Rows where latest_alert = 'ANOMALY', with anomaly score
SELECT
    account_id,
    customer_name,
    segment_name,
    billing_month,
    total_cost,
    avg_anomaly_score,
    latest_alert
FROM SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
WHERE latest_alert = 'ANOMALY'
  AND billing_month = DATE_TRUNC('month', CURRENT_DATE())
ORDER BY avg_anomaly_score DESC;

-- Example 3: Segment comparison over last 3 months
-- Use case: "Compare average costs: Enterprise vs SMB vs Commercial, last 3 months"
-- Expected: Time-series table with segment, month, avg_cost, account_count
SELECT
    segment_name,
    billing_month,
    AVG(total_cost) AS avg_cost,
    COUNT(DISTINCT account_id) AS account_count,
    SUM(total_cost) AS segment_total
FROM SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
WHERE billing_month >= DATEADD('month', -3, DATE_TRUNC('month', CURRENT_DATE()))
GROUP BY segment_name, billing_month
ORDER BY billing_month DESC, avg_cost DESC;

-- Example 4: Single account cost breakdown by service type
-- Use case: "What were the costs for account 12345 in October 2024?"
-- Expected: Single row with voice/data/sms cost breakdown
SELECT
    account_id,
    customer_name,
    billing_month,
    voice_cost,
    data_cost,
    sms_cost,
    total_cost,
    ROUND((voice_cost / NULLIF(total_cost, 0)) * 100, 1) AS voice_pct,
    ROUND((data_cost / NULLIF(total_cost, 0)) * 100, 1) AS data_pct,
    ROUND((sms_cost / NULLIF(total_cost, 0)) * 100, 1) AS sms_pct
FROM SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
WHERE account_id = 12345
  AND billing_month = '2024-10-01';

-- Example 5: Month-over-month cost increase detection
-- Use case: "Which accounts had cost increases over 20% month-over-month?"
-- Expected: Accounts with MoM variance, sorted by variance DESC
WITH monthly_costs AS (
    SELECT
        account_id,
        customer_name,
        segment_name,
        billing_month,
        total_cost,
        LAG(total_cost) OVER (PARTITION BY account_id ORDER BY billing_month) AS prev_month_cost
    FROM SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
)
SELECT
    account_id,
    customer_name,
    segment_name,
    billing_month,
    prev_month_cost,
    total_cost AS current_month_cost,
    total_cost - prev_month_cost AS cost_change,
    ROUND(((total_cost - prev_month_cost) / NULLIF(prev_month_cost, 0)) * 100, 1) AS pct_change
FROM monthly_costs
WHERE prev_month_cost IS NOT NULL
  AND ((total_cost - prev_month_cost) / NULLIF(prev_month_cost, 0)) > 0.20
ORDER BY pct_change DESC;

-- Example 6: Enterprise segment cost trend (last 6 months)
-- Use case: "Show me the cost trend for Enterprise accounts over the last 6 months"
-- Expected: Time-series with monthly totals, averages, account counts
SELECT
    billing_month,
    COUNT(DISTINCT account_id) AS enterprise_account_count,
    SUM(total_cost) AS total_segment_cost,
    AVG(total_cost) AS avg_account_cost,
    MIN(total_cost) AS min_account_cost,
    MAX(total_cost) AS max_account_cost
FROM SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
WHERE segment_name = 'Enterprise'
  AND billing_month >= DATEADD('month', -6, DATE_TRUNC('month', CURRENT_DATE()))
GROUP BY billing_month
ORDER BY billing_month DESC;

/*******************************************************************************
 * VALIDATION CHECKLIST
 * 
 * Before deploying semantic view changes:
 * ✓ All 6 example queries execute without error
 * ✓ Each query returns expected column names and types
 * ✓ Results are non-empty (for months with data)
 * ✓ Performance: Each query completes in <5 seconds on X-SMALL warehouse
 * ✓ SQL is sargable (no functions on WHERE clause columns)
 * ✓ Agent instructions updated to match any query pattern changes
 * 
 * To validate: Execute each query block and verify results.
 * Last validated: [Update this date when re-validating]
 ******************************************************************************/
