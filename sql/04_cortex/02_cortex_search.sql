/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 02_cortex_search.sql
 * PURPOSE: Create Cortex Search service for billing knowledge base.
 * 
 * OBJECTS CREATED:
 *   - CORTEX SEARCH SERVICE SFE_SHARED_KNOWLEDGE.SFE_BILLING_SEARCH
 * 
 * PERFORMANCE OPTIMIZATION:
 *   - INITIALIZE = ON_SCHEDULE: Service created instantly, embeddings generated asynchronously
 *   - TARGET_LAG = '1 minute': Service ready ~60 seconds after deployment (for demo speed)
 *   - For production: Use TARGET_LAG = '1 hour' or longer to reduce refresh costs
 * 
 * VERIFICATION:
 *   Check indexing status:
 *     SELECT SYSTEM$GET_CORTEX_SEARCH_SERVICE_STATUS('SFE_SHARED_KNOWLEDGE.SFE_BILLING_SEARCH');
 *   Wait until status shows "READY" before testing search queries.
 * 
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE CORTEX SEARCH SERVICE SFE_SHARED_KNOWLEDGE.SFE_BILLING_SEARCH
    ON doc_body
    ATTRIBUTES doc_type, region_code
    WAREHOUSE = SFE_BILLING_WH
    TARGET_LAG = '1 minute'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
    INITIALIZE = ON_SCHEDULE
    COMMENT = 'DEMO: Semantic search over billing guardrails and FAQs (fast deployment, deferred indexing)'
AS
SELECT
    doc_body,
    doc_title,
    doc_type,
    region_code,
    last_reviewed
FROM SFE_SHARED_KNOWLEDGE.BILLING_KB;
