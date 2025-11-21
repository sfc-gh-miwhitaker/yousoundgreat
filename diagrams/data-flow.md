# Data Flow - YouSoundGreat Billing Intelligence
Author: SE Community  
Last Updated: 2025-11-21  
Expires: 2025-12-21 (30 days from creation)  
Status: Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

Reference Implementation: This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.
## Overview
End-to-end movement of telecom billing data from Kafka streams and SaaS sources through Snowflake ingestion, transformation, Cortex AI enrichment, and consumption channels (Snowflake Intelligence, Streamlit dashboards, APIs).
## Diagram
```mermaid
graph TB
    subgraph Sources
        KAFKA[Kafka Streaming<br/>Usage Events]
        SFDC[Salesforce Billing Accounts]
        GA4[Google Analytics 4 Export]
    end

    subgraph Ingestion
        STREAM[Snowpipe Streaming<br/>SFE_RAW_BILLING.USAGE_METRICS]
        COPY[Batch COPY INTO<br/>SFE_RAW_BILLING.CUSTOMER_SEGMENTS]
        CONNECTOR[Salesforce Connector Tasks]
    end

    subgraph Storage_Layers
        RAW[(SFE_RAW_BILLING)]
        STG[(SFE_STG_TELECOM)]
        ANALYTICS[(SFE_ANALYTICS_COSTS)]
    end

    subgraph Processing
        DT[Dynamic Table<br/>DT_ACCOUNT_BILLING]
        CLASSIFY[SNOWFLAKE.ML.CLASSIFICATION
                 SFE_CHURN_CLASSIFIER]
        SEARCH[CREATE CORTEX SEARCH SERVICE
               SFE_BILLING_SEARCH]
    end

    subgraph Consumption
        AGENT[Snowflake Intelligence Agent]
        STREAMLIT[Streamlit Billing Ops App]
        ALERTS[Resource Monitors & Cost Alerts]
    end

    KAFKA -->|JSON rowset| STREAM
    GA4 -->|CSV batches| COPY
    SFDC -->|API sync| CONNECTOR
    STREAM --> RAW
    COPY --> RAW
    CONNECTOR --> RAW
    RAW -->|standardize, mask| STG
    STG -->|aggregate, join| ANALYTICS
    ANALYTICS -->|incremental refresh| DT
    ANALYTICS -->|feature view| CLASSIFY
    ANALYTICS -->|documents + metrics| SEARCH
    DT --> AGENT
    CLASSIFY --> STREAMLIT
    SEARCH --> AGENT
    DT --> STREAMLIT
    ALERTS --> STREAMLIT
```
## Component Descriptions
- Purpose: Snowpipe Streaming for Kafka writes billing usage into `SFE_RAW_BILLING.USAGE_METRICS` within seconds.
  - Technology: Snowpipe Streaming INGEST API + Kafka connector.
  - Location: `sql/02_data/02_load_sample_data.sql`
  - Deps: Kafka topic, `SFE_BILLING_WH`.
- Purpose: Dynamic table `SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING` keeps aggregates <15 min old for AI agents.
  - Technology: `CREATE DYNAMIC TABLE ... TARGET_LAG = '15 minutes'`.
  - Location: `sql/03_transformations/03_create_tasks.sql`
  - Deps: `FCT_ACCOUNT_COSTS`, warehouse `SFE_BILLING_WH`.
- Purpose: Cortex Search service `SFE_BILLING_SEARCH` powers semantic lookup of billing policies.
  - Technology: `CREATE CORTEX SEARCH SERVICE ... EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'`.
  - Location: `sql/04_cortex/02_cortex_search.sql`
  - Deps: staged documentation table, `SFE_BILLING_WH`.
- Purpose: Snowflake Intelligence Agent `SFE_BILLING_AGENT` provides NL cost queries.
  - Technology: Snowflake Intelligence / Cortex Analyst agent config referencing semantic models + search.
  - Location: `sql/04_cortex/03_intelligence_agent.sql`
  - Deps: `DT_ACCOUNT_BILLING`, `SFE_BILLING_SEARCH`, cost warehouse.
## Change History
See `.cursor/DIAGRAM_CHANGELOG.md` for vhistory.
