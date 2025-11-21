# Data Model - YouSoundGreat Billing Intelligence
Author: SE Community  
Last Updated: 2025-11-21  
Expires: 2025-12-21 (30 days from creation)  
Status: Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

Reference Implementation: This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.
## Overview
Logical data model for the TelecomCorp billing intelligence demo showing how raw usage feeds staging, analytics, Cortex-ready datasets, and governance tables inside `SNOWFLAKE_EXAMPLE`.
## Diagram
```mermaid
erDiagram
    SFE_RAW_BILLING.USAGE_METRICS ||--o{ SFE_STG_TELECOM.STG_USAGE_ENRICHED : aggregates
    SFE_RAW_BILLING.CUSTOMER_SEGMENTS ||--o{ SFE_ANALYTICS_COSTS.DIM_CUSTOMER : maps
    SFE_RAW_BILLING.COST_ALLOCATIONS ||--o{ SFE_ANALYTICS_COSTS.FCT_ACCOUNT_COSTS : allocates
    SFE_ANALYTICS_COSTS.DIM_CUSTOMER ||--o{ SFE_ANALYTICS_COSTS.FCT_ACCOUNT_COSTS : describes
    SFE_ANALYTICS_COSTS.FCT_ACCOUNT_COSTS ||--|| SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING : feeds

    SFE_RAW_BILLING.USAGE_METRICS {
        NUMBER usage_id PK
        NUMBER account_id
        TIMESTAMP_NTZ usage_ts
        NUMBER minutes_used
        NUMBER data_mb
        NUMBER cost_amount
        VARCHAR service_type
        VARCHAR ingest_source
    }

    SFE_RAW_BILLING.CUSTOMER_SEGMENTS {
        NUMBER segment_id PK
        NUMBER account_id
        VARCHAR segment_name
        VARCHAR tier
        TIMESTAMP_NTZ effective_start
        TIMESTAMP_NTZ effective_end
    }

    SFE_RAW_BILLING.COST_ALLOCATIONS {
        NUMBER allocation_id PK
        NUMBER usage_id FK
        VARCHAR cost_bucket
        NUMBER bucket_amount
        TIMESTAMP_NTZ billed_at
    }

    SFE_STG_TELECOM.STG_USAGE_ENRICHED {
        NUMBER usage_id PK
        NUMBER account_id
        TIMESTAMP_NTZ usage_ts
        NUMBER total_cost
        VARCHAR region_code
        VARCHAR anomaly_flag
        TIMESTAMP_NTZ staged_at
    }

    SFE_ANALYTICS_COSTS.DIM_CUSTOMER {
        NUMBER customer_key PK
        NUMBER account_id UK
        VARCHAR customer_name
        VARCHAR segment_name
        VARCHAR geography
        VARCHAR lifecycle_status
        TIMESTAMP_NTZ updated_at
    }

    SFE_ANALYTICS_COSTS.FCT_ACCOUNT_COSTS {
        NUMBER billing_key PK
        NUMBER customer_key FK
        NUMBER usage_id FK
        DATE billing_date
        NUMBER voice_cost
        NUMBER data_cost
        NUMBER sms_cost
        NUMBER total_cost
        NUMBER anomaly_score
    }

    SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING {
        NUMBER billing_key PK
        NUMBER customer_key
        DATE billing_date
        NUMBER total_cost
        NUMBER anomaly_score
        VARCHAR cost_alert
        TIMESTAMP_NTZ refreshed_at
    }
```
## Component Descriptions
- Purpose: `SFE_RAW_BILLING.USAGE_METRICS` captures unprocessed usage from Kafka/Snowpipe streaming.
  - Technology: Snowflake permanent table with ingestion from Snowpipe Streaming.
  - Location: `sql/02_data/01_create_tables.sql`
  - Deps: Kafka connector, `SFE_BILLING_WH`
- Purpose: `SFE_STG_TELECOM.STG_USAGE_ENRICHED` standardizes usage units and tags anomalies for ML.
  - Technology: SQL transformations + dynamic table refresh.
  - Location: `sql/03_transformations/02_create_views.sql`
  - Deps: `SFE_RAW_BILLING` tables, masking policies.
- Purpose: `SFE_ANALYTICS_COSTS.FCT_ACCOUNT_COSTS` is the curated billing fact powering Cortex ML & dashboards.
  - Technology: Snowflake analytic table refreshed via tasks.
  - Location: `sql/03_transformations/01_create_streams.sql`
  - Deps: staging view, `SFE_ANALYTICS_COSTS.DIM_CUSTOMER`.
- Purpose: `SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING` surfaces ready-to-query aggregates for Snowflake Intelligence.
  - Technology: Dynamic table with `TARGET_LAG = '15 minutes'`.
  - Location: `sql/03_transformations/02_create_views.sql`
  - Deps: `SFE_BILLING_WH`, `FCT_ACCOUNT_COSTS`.
## Change History
See `.cursor/DIAGRAM_CHANGELOG.md` for vhistory.
