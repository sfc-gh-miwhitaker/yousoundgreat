/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 01_create_tables.sql
 * PURPOSE: Create raw, staging, analytics, and knowledge tables.
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SFE_RAW_BILLING.USAGE_METRICS
 *   - SNOWFLAKE_EXAMPLE.SFE_RAW_BILLING.CUSTOMER_SEGMENTS
 *   - SNOWFLAKE_EXAMPLE.SFE_RAW_BILLING.COST_ALLOCATIONS
 *   - SNOWFLAKE_EXAMPLE.SFE_STG_TELECOM.STG_USAGE_ENRICHED
 *   - SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.DIM_CUSTOMER
 *   - SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.FCT_ACCOUNT_COSTS
 *   - SNOWFLAKE_EXAMPLE.SFE_SHARED_KNOWLEDGE.BILLING_KB
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE TABLE SFE_RAW_BILLING.USAGE_METRICS (
    usage_id NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    account_id NUMBER,
    usage_ts TIMESTAMP_NTZ,
    minutes_used NUMBER(12,2),
    data_mb NUMBER(12,2),
    sms_count NUMBER,
    service_type VARCHAR,
    cost_amount NUMBER(12,4),
    region_code VARCHAR,
    ingest_source VARCHAR,
    load_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    row_comment VARCHAR
) COMMENT = 'DEMO: Raw telecom usage events ingested via Snowpipe Streaming';

CREATE OR REPLACE TABLE SFE_RAW_BILLING.CUSTOMER_SEGMENTS (
    segment_id NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    account_id NUMBER,
    customer_name VARCHAR,
    segment_name VARCHAR,
    lifecycle_status VARCHAR,
    tier VARCHAR,
    effective_start DATE,
    effective_end DATE,
    row_comment VARCHAR
) COMMENT = 'DEMO: Master data for telecom customer segmentation';

CREATE OR REPLACE TABLE SFE_RAW_BILLING.COST_ALLOCATIONS (
    allocation_id NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    usage_id NUMBER,
    cost_bucket VARCHAR,
    bucket_amount NUMBER(12,4),
    billed_at DATE,
    notes VARCHAR
) COMMENT = 'DEMO: Derived cost buckets for usage events';

CREATE OR REPLACE TABLE SFE_STG_TELECOM.STG_USAGE_ENRICHED (
    usage_id NUMBER,
    account_id NUMBER,
    usage_ts TIMESTAMP_NTZ,
    total_cost NUMBER(12,4),
    service_type VARCHAR,
    region_code VARCHAR,
    anomaly_flag VARCHAR,
    staged_at TIMESTAMP_NTZ,
    segment_name VARCHAR,
    cost_bucket VARCHAR
) COMMENT = 'DEMO: Standardized staging view for analytics + ML';

CREATE OR REPLACE TABLE SFE_ANALYTICS_COSTS.DIM_CUSTOMER (
    customer_key NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    account_id NUMBER,
    customer_name VARCHAR,
    segment_name VARCHAR,
    geography VARCHAR,
    lifecycle_status VARCHAR,
    avg_monthly_cost NUMBER(12,4),
    last_active_ts TIMESTAMP_NTZ
) COMMENT = 'DEMO: Curated customer dimension referenced by facts';

CREATE OR REPLACE TABLE SFE_ANALYTICS_COSTS.FCT_ACCOUNT_COSTS (
    billing_key NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    customer_key NUMBER,
    account_id NUMBER,
    usage_id NUMBER,
    billing_month DATE,
    voice_cost NUMBER(12,4),
    data_cost NUMBER(12,4),
    sms_cost NUMBER(12,4),
    other_cost NUMBER(12,4),
    total_cost NUMBER(12,4),
    anomaly_score NUMBER(6,4),
    alert_label VARCHAR
) COMMENT = 'DEMO: Billing fact table powering dashboards + ML';

CREATE OR REPLACE TABLE SFE_SHARED_KNOWLEDGE.BILLING_KB (
    doc_id NUMBER AUTOINCREMENT START 1 INCREMENT 1,
    doc_type VARCHAR,
    doc_title VARCHAR,
    doc_body VARCHAR,
    region_code VARCHAR,
    last_reviewed DATE
) COMMENT = 'DEMO: Reference knowledge base for Cortex Search';
