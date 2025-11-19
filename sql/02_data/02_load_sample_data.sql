/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 02_load_sample_data.sql
 * PURPOSE: Generate synthetic telecom billing data for demos.
 * OBJECTS TARGETED:
 *   - Inserts into SFE_RAW_BILLING.* tables
 *   - Seeds SFE_ANALYTICS_COSTS.DIM_CUSTOMER
 *   - Seeds SFE_SHARED_KNOWLEDGE.BILLING_KB
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

SET usage_rowcount = 5000;

TRUNCATE TABLE SFE_RAW_BILLING.USAGE_METRICS;

INSERT INTO SFE_RAW_BILLING.USAGE_METRICS (
    account_id,
    usage_ts,
    minutes_used,
    data_mb,
    sms_count,
    service_type,
    cost_amount,
    region_code,
    ingest_source,
    load_ts,
    row_comment
)
WITH usage_source AS (
    SELECT
        seq4() AS seq_id,
        (10000 + UNIFORM(1, 9000, RANDOM()))::NUMBER AS account_id,
        DATEADD('minute', -1 * seq4()::INT, CURRENT_TIMESTAMP()) AS usage_ts,
        UNIFORM(1, 120, RANDOM()) AS minutes_used,
        UNIFORM(1, 2000, RANDOM()) / 10 AS data_mb,
        UNIFORM(1, 20, RANDOM()) AS sms_count,
        ARRAY_CONSTRUCT('voice', 'data', 'sms')[1 + MOD(UNIFORM(0, 1000, RANDOM()), 3)]::STRING AS service_type,
        ROUND(UNIFORM(5, 5000, RANDOM()) / 100, 2) AS cost_amount,
        ARRAY_CONSTRUCT('NAMER', 'EMEA', 'APAC', 'LATAM')[1 + MOD(UNIFORM(0, 1000, RANDOM()), 4)]::STRING AS region_code,
        ARRAY_CONSTRUCT('kafka', 'salesforce', 'ga4')[1 + MOD(UNIFORM(0, 1000, RANDOM()), 3)]::STRING AS ingest_source
    FROM TABLE(GENERATOR(ROWCOUNT => $usage_rowcount))
)
SELECT
    account_id,
    usage_ts,
    minutes_used::NUMBER(12,2),
    data_mb::NUMBER(12,2),
    sms_count,
    service_type,
    cost_amount::NUMBER(12,4),
    region_code,
    ingest_source,
    CURRENT_TIMESTAMP(),
    'DEMO: generated via TABLE(GENERATOR())'
FROM usage_source;

TRUNCATE TABLE SFE_RAW_BILLING.CUSTOMER_SEGMENTS;

INSERT INTO SFE_RAW_BILLING.CUSTOMER_SEGMENTS (
    account_id,
    customer_name,
    segment_name,
    lifecycle_status,
    tier,
    effective_start,
    effective_end,
    row_comment
)
WITH segment_source AS (
    SELECT DISTINCT
        account_id,
        -- Use account_id directly for deterministic customer name
        CONCAT('Customer_', LPAD(account_id::STRING, 5, '0')) AS customer_name,
        -- Use ABS(HASH()) to ensure positive values before MOD
        ARRAY_CONSTRUCT('Enterprise', 'Commercial', 'SMB')[MOD(ABS(HASH(account_id)), 3)]::STRING AS segment_name,
        ARRAY_CONSTRUCT('Active', 'At Risk', 'Churned')[MOD(ABS(HASH(account_id * 2)), 3)]::STRING AS lifecycle_status,
        ARRAY_CONSTRUCT('Gold', 'Silver', 'Bronze')[MOD(ABS(HASH(account_id * 3)), 3)]::STRING AS tier
    FROM SFE_RAW_BILLING.USAGE_METRICS
)
SELECT
    account_id,
    customer_name,
    segment_name,
    lifecycle_status,
    tier,
    DATEADD('day', -90, CURRENT_DATE()),
    NULL,
    'DEMO: synthetic customer segment row'
FROM segment_source;

TRUNCATE TABLE SFE_RAW_BILLING.COST_ALLOCATIONS;

INSERT INTO SFE_RAW_BILLING.COST_ALLOCATIONS (
    usage_id,
    cost_bucket,
    bucket_amount,
    billed_at,
    notes
)
SELECT
    usage_id,
    VALUE:bucket_name::STRING AS bucket_name,
    ROUND(cost_amount * VALUE:bucket_pct::FLOAT, 4) AS bucket_amount,
    DATE_TRUNC('month', usage_ts) AS billed_at,
    'DEMO allocation' AS notes
FROM SFE_RAW_BILLING.USAGE_METRICS,
     LATERAL FLATTEN(INPUT => ARRAY_CONSTRUCT(
        OBJECT_CONSTRUCT('bucket_name', 'voice', 'bucket_pct', 0.4),
        OBJECT_CONSTRUCT('bucket_name', 'data', 'bucket_pct', 0.5),
        OBJECT_CONSTRUCT('bucket_name', 'sms', 'bucket_pct', 0.1)
     ));

TRUNCATE TABLE SFE_ANALYTICS_COSTS.DIM_CUSTOMER;

INSERT INTO SFE_ANALYTICS_COSTS.DIM_CUSTOMER (
    account_id,
    customer_name,
    segment_name,
    geography,
    lifecycle_status,
    avg_monthly_cost,
    last_active_ts
)
SELECT
    seg.account_id,
    seg.customer_name,
    seg.segment_name,
    -- Use ABS(HASH()) for deterministic geography assignment
    ARRAY_CONSTRUCT('NAMER', 'EMEA', 'APAC', 'LATAM')[MOD(ABS(HASH(seg.account_id * 4)), 4)]::STRING,
    seg.lifecycle_status,
    ROUND(AVG(usage.cost_amount), 2) AS avg_monthly_cost,
    MAX(usage.usage_ts) AS last_active_ts
FROM SFE_RAW_BILLING.CUSTOMER_SEGMENTS AS seg
JOIN SFE_RAW_BILLING.USAGE_METRICS AS usage
    ON seg.account_id = usage.account_id
GROUP BY
    seg.account_id,
    seg.customer_name,
    seg.segment_name,
    seg.lifecycle_status;

TRUNCATE TABLE SFE_SHARED_KNOWLEDGE.BILLING_KB;

INSERT INTO SFE_SHARED_KNOWLEDGE.BILLING_KB (doc_type, doc_title, doc_body, region_code, last_reviewed)
SELECT doc_type, doc_title, doc_body, region_code, last_reviewed
FROM VALUES
    ('playbook', 'Cost Guardrails', 'Set auto-suspend to 60 seconds for shared warehouses.', 'NAMER', CURRENT_DATE()),
    ('faq', 'Anomaly Detection FAQ', 'Cortex classification flags cost spikes beyond 2x baseline.', 'EMEA', CURRENT_DATE()),
    ('policy', 'Billing Escalation Policy', 'Escalate >$10k variances to Finance Ops within 4 hours.', 'APAC', CURRENT_DATE())
    AS kb(doc_type, doc_title, doc_body, region_code, last_reviewed);
