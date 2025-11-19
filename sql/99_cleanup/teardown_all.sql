/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: teardown_all.sql
 * PURPOSE: Remove demo-specific objects without touching shared infrastructure.
 ******************************************************************************/
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

-- Stop tasks before dropping
ALTER TASK IF EXISTS SFE_STG_TELECOM.SFE_PIPELINE_USAGE_TO_STG SUSPEND;
ALTER TASK IF EXISTS SFE_ANALYTICS_COSTS.SFE_PIPELINE_STG_TO_FACT SUSPEND;

-- Drop tasks and streams
DROP TASK IF EXISTS SFE_STG_TELECOM.SFE_PIPELINE_USAGE_TO_STG;
DROP TASK IF EXISTS SFE_ANALYTICS_COSTS.SFE_PIPELINE_STG_TO_FACT;
DROP STREAM IF EXISTS SFE_RAW_BILLING.USAGE_METRICS_STREAM;
DROP STREAM IF EXISTS SFE_RAW_BILLING.COST_ALLOC_STREAM;

-- Drop ML + Cortex assets
DROP SNOWFLAKE.ML.CLASSIFICATION IF EXISTS SFE_ANALYTICS_COSTS.SFE_USAGE_ANOMALY_MODEL;
DROP SEMANTIC VIEW IF EXISTS SFE_ANALYTICS_COSTS.SV_ACCOUNT_BILLING;

-- Drop Cortex Search Service (no IF EXISTS support, wrapped in error handler)
BEGIN
    DROP CORTEX SEARCH SERVICE SFE_SHARED_KNOWLEDGE.SFE_BILLING_SEARCH;
EXCEPTION
    WHEN OTHER THEN
        -- Ignore error if service doesn't exist
        NULL;
END;

-- Drop agent from Snowflake Intelligence shared schema
-- Note: snowflake_intelligence.agents schema is shared infrastructure - do NOT drop it
USE DATABASE snowflake_intelligence;
DROP AGENT IF EXISTS agents.SFE_BILLING_AGENT;

-- Drop Streamlit app from project schema
USE DATABASE SNOWFLAKE_EXAMPLE;
DROP STREAMLIT IF EXISTS SFE_ANALYTICS_COSTS.SFE_BILLING_STREAMLIT;

-- Drop Git repo clone (keep API integration per shared use)
DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO;

-- Drop warehouse
DROP WAREHOUSE IF EXISTS SFE_BILLING_WH;

-- Drop schemas with cascade
DROP SCHEMA IF EXISTS SFE_SHARED_KNOWLEDGE CASCADE;
DROP SCHEMA IF EXISTS SFE_ANALYTICS_COSTS CASCADE;
DROP SCHEMA IF EXISTS SFE_STG_TELECOM CASCADE;
DROP SCHEMA IF EXISTS SFE_RAW_BILLING CASCADE;

-- PROTECTED SHARED INFRASTRUCTURE (preserved for other projects):
-- - snowflake_intelligence database (organizational Snowflake Intelligence repository)
-- - snowflake_intelligence.agents schema (agent discovery namespace)
-- - SNOWFLAKE_EXAMPLE database (demo database)
-- - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared Git repository namespace)
-- - SFE_GIT_API_INTEGRATION (shared API integration)
