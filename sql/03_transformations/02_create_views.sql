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
