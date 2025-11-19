# Network Flow - YouSoundGreat Billing Intelligence
Author: Michael Whitaker
Last Updated: 2025-11-18
Status: Reference Impl
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)
Reference Impl: This code demonstrates prod-grade architectural patterns and best practice. review and customize security, networking, logic for your organization's specific requirements before deployment.
## Overview
Connectivity view for billing analysts, Snowflake services, upstream SaaS APIs, and secured traffic paths required for the all-Snowflake implementation.
## Diagram
```mermaid
graph TB
    subgraph External Users
        Analyst[Billing Analyst
        Laptop]
        Exec[Finance Exec]
    end

    subgraph Identity & Edge
        IdP[Okta SSO
        SAML / OIDC]
        WAF[Customer WAF
        :443 HTTPS]
    end

    subgraph Snowflake Account (AWS us-west-2)
        LB[Snowflake Front Door
        TLS 1.2 :443]
        Snowsight[Snowsight UI
        https://app.snowflake.com]
        StreamlitSvc[Streamlit Service
        :443 HTTPS]
        Warehouse[SFE_BILLING_WH
        Compute]
        Stage[Internal Stage
        @SNOWFLAKE_EXAMPLE.RAW]
        Cortex[Cortex Services
        (ML, Search, Intelligence)]
    end

    subgraph Integrations
        KafkaCloud[Kafka REST Proxy
        :443 HTTPS]
        Salesforce[Salesforce REST API
        :443 HTTPS]
        GA4Export[Google Analytics Export
        GCS + HTTPS]
    end

    Analyst -->|SAML| IdP -->|SAML Assertion| LB
    Exec -->|SSO| IdP
    LB --> Snowsight
    LB --> StreamlitSvc
    Snowsight --> Warehouse
    StreamlitSvc --> Warehouse
    Warehouse --> Stage
    Warehouse --> Cortex
    KafkaCloud -->|Snowpipe Streaming :443| Stage
    Salesforce -->|External Function :443| Warehouse
    GA4Export -->|Secure COPY via Stage| Stage
    Cortex --> Snowsight
    Cortex --> StreamlitSvc
```
## Component Descriptions
- Purpose: `SFE_BILLING_WH` executes ingestion, dynamic tables, Cortex training queries.
  - Technology: XSMALL standard warehouse with auto-suspend 60s.
  - Location: `sql/00_deploy_all.sql`
  - Deps: ACCOUNTADMIN role to create.
- Purpose: Streamlit in Snowflake surface exposes billing dashboards via HTTPS.
  - Technology: `CREATE STREAMLIT` bound to `SFE_BILLING_WH`.
  - Location: `sql/05_streamlit/01_create_streamlit.sql`
  - Deps: Snowsight networking, role ownership.
- Purpose: Kafka REST proxy sends TLS-encrypted rowsets to Snowpipe Streaming ingestion endpoint.
  - Technology: Snowpipe Streaming client with key-pair auth.
  - Location: `docs/02-DEPLOYMENT.md` integration steps.
  - Deps: API integration `SFE_GIT_API_INTEGRATION`, firewall allowlist.
## Change History
See `.cursor/DIAGRAM_CHANGELOG.md` for vhistory.
