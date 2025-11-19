/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 02_cortex_search.sql
 * PURPOSE: Create Cortex Search service for billing knowledge base.
 * OBJECTS CREATED:
 *   - CORTEX SEARCH SERVICE SFE_SHARED_KNOWLEDGE.SFE_BILLING_SEARCH
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE CORTEX SEARCH SERVICE SFE_SHARED_KNOWLEDGE.SFE_BILLING_SEARCH
    ON doc_body
    ATTRIBUTES doc_type, region_code
    WAREHOUSE = SFE_BILLING_WH
    TARGET_LAG = '1 hour'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
    COMMENT = 'DEMO: Semantic search over billing guardrails and FAQs'
AS
SELECT
    doc_body,
    doc_title,
    doc_type,
    region_code,
    last_reviewed
FROM SFE_SHARED_KNOWLEDGE.BILLING_KB;
