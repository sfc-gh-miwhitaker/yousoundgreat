/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 03_create_tasks.sql
 * PURPOSE: Automate ingestion + fact table refresh via Snowflake tasks.
 * OBJECTS CREATED:
 *   - TASK SFE_PIPELINE_USAGE_TO_STG
 *   - TASK SFE_PIPELINE_STG_TO_FACT
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE TASK SFE_STG_TELECOM.SFE_PIPELINE_USAGE_TO_STG
    WAREHOUSE = SFE_BILLING_WH
    SCHEDULE = '5 MINUTE'
    COMMENT = 'DEMO: Consumes raw usage stream and maintains staging table'
    WHEN SYSTEM$STREAM_HAS_DATA('SNOWFLAKE_EXAMPLE.SFE_RAW_BILLING.USAGE_METRICS_STREAM')
AS
MERGE INTO SFE_STG_TELECOM.STG_USAGE_ENRICHED AS tgt
USING (
    SELECT
        stream.usage_id,
        stream.account_id,
        stream.usage_ts,
        stream.minutes_used,
        stream.data_mb,
        stream.sms_count,
        stream.service_type,
        stream.cost_amount,
        stream.region_code,
        seg.segment_name,
        seg.lifecycle_status,
        alloc.cost_bucket,
        alloc.bucket_amount,
        CASE WHEN stream.cost_amount > AVG(stream.cost_amount) OVER (PARTITION BY stream.account_id) * 1.4 THEN 'ANOMALY' ELSE 'NORMAL' END AS anomaly_flag,
        CURRENT_TIMESTAMP() AS staged_at
    FROM SNOWFLAKE_EXAMPLE.SFE_RAW_BILLING.USAGE_METRICS_STREAM AS stream
    LEFT JOIN SFE_RAW_BILLING.CUSTOMER_SEGMENTS AS seg
        ON stream.account_id = seg.account_id
    LEFT JOIN SFE_RAW_BILLING.COST_ALLOCATIONS AS alloc
        ON stream.usage_id = alloc.usage_id
    WHERE METADATA$ACTION IN ('INSERT', 'UPDATE')
) AS src
ON tgt.usage_id = src.usage_id
WHEN MATCHED THEN UPDATE SET
    account_id = src.account_id,
    usage_ts = src.usage_ts,
    total_cost = src.cost_amount,
    service_type = src.service_type,
    region_code = src.region_code,
    anomaly_flag = src.anomaly_flag,
    staged_at = src.staged_at,
    segment_name = src.segment_name,
    cost_bucket = COALESCE(src.cost_bucket, src.service_type)
WHEN NOT MATCHED THEN INSERT (
    usage_id,
    account_id,
    usage_ts,
    total_cost,
    service_type,
    region_code,
    anomaly_flag,
    staged_at,
    segment_name,
    cost_bucket
) VALUES (
    src.usage_id,
    src.account_id,
    src.usage_ts,
    src.cost_amount,
    src.service_type,
    src.region_code,
    src.anomaly_flag,
    src.staged_at,
    src.segment_name,
    COALESCE(src.cost_bucket, src.service_type)
);

CREATE OR REPLACE TASK SFE_ANALYTICS_COSTS.SFE_PIPELINE_STG_TO_FACT
    WAREHOUSE = SFE_BILLING_WH
    SCHEDULE = '15 MINUTE'
    COMMENT = 'DEMO: Updates fact table from staging records when allocations change'
    WHEN SYSTEM$STREAM_HAS_DATA('SNOWFLAKE_EXAMPLE.SFE_RAW_BILLING.COST_ALLOC_STREAM')
AS
MERGE INTO SFE_ANALYTICS_COSTS.FCT_ACCOUNT_COSTS AS tgt
USING (
    SELECT
        stg.account_id,
        dim.customer_key,
        stg.usage_id,
        DATE_TRUNC('month', stg.usage_ts) AS billing_month,
        IFF(stg.service_type = 'voice', stg.bucket_amount, 0) AS voice_cost,
        IFF(stg.service_type = 'data', stg.bucket_amount, 0) AS data_cost,
        IFF(stg.service_type = 'sms', stg.bucket_amount, 0) AS sms_cost,
        stg.bucket_amount AS total_cost,
        stg.anomaly_score,
        stg.anomaly_flag
    FROM SFE_STG_TELECOM.STG_USAGE_ENRICHED AS stg
    JOIN SFE_ANALYTICS_COSTS.DIM_CUSTOMER AS dim
        ON stg.account_id = dim.account_id
) AS src
ON tgt.usage_id = src.usage_id
WHEN MATCHED THEN UPDATE SET
    customer_key = src.customer_key,
    billing_month = src.billing_month,
    voice_cost = src.voice_cost,
    data_cost = src.data_cost,
    sms_cost = src.sms_cost,
    other_cost = 0,
    total_cost = src.total_cost,
    anomaly_score = src.anomaly_score,
    alert_label = src.anomaly_flag
WHEN NOT MATCHED THEN INSERT (
    customer_key,
    account_id,
    usage_id,
    billing_month,
    voice_cost,
    data_cost,
    sms_cost,
    other_cost,
    total_cost,
    anomaly_score,
    alert_label
) VALUES (
    src.customer_key,
    src.account_id,
    src.usage_id,
    src.billing_month,
    src.voice_cost,
    src.data_cost,
    src.sms_cost,
    0,
    src.total_cost,
    src.anomaly_score,
    src.anomaly_flag
);

ALTER TASK SFE_STG_TELECOM.SFE_PIPELINE_USAGE_TO_STG RESUME;
ALTER TASK SFE_ANALYTICS_COSTS.SFE_PIPELINE_STG_TO_FACT RESUME;
