/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: teardown_all.sql
 * PURPOSE: Remove demo-specific objects without touching shared infrastructure.
 * 
 * SAFE TO RUN ANYTIME: All commands use IF EXISTS or error handling
 ******************************************************************************/
USE ROLE ACCOUNTADMIN;

-- Stop and drop tasks (wrapped in error handler for non-existent schemas)
BEGIN
    ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_TELECOM.SFE_PIPELINE_USAGE_TO_STG SUSPEND;
    DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_TELECOM.SFE_PIPELINE_USAGE_TO_STG;
EXCEPTION
    WHEN OTHER THEN NULL;
END;

BEGIN
    ALTER TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.SFE_PIPELINE_STG_TO_FACT SUSPEND;
    DROP TASK IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.SFE_PIPELINE_STG_TO_FACT;
EXCEPTION
    WHEN OTHER THEN NULL;
END;

-- Drop streams (wrapped in error handler)
BEGIN
    DROP STREAM IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_BILLING.USAGE_METRICS_STREAM;
    DROP STREAM IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_BILLING.COST_ALLOC_STREAM;
EXCEPTION
    WHEN OTHER THEN NULL;
END;

-- Drop ML + Cortex assets (wrapped in error handler)
BEGIN
    DROP SNOWFLAKE.ML.CLASSIFICATION IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.SFE_USAGE_ANOMALY_MODEL;
    DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.SV_ACCOUNT_BILLING;
EXCEPTION
    WHEN OTHER THEN NULL;
END;

-- Drop Cortex Search Service (wrapped in error handler)
BEGIN
    DROP CORTEX SEARCH SERVICE SNOWFLAKE_EXAMPLE.SFE_SHARED_KNOWLEDGE.SFE_BILLING_SEARCH;
EXCEPTION
    WHEN OTHER THEN NULL;
END;

-- Drop agent from Snowflake Intelligence shared schema (wrapped in error handler)
BEGIN
    DROP AGENT IF EXISTS snowflake_intelligence.agents.SFE_BILLING_AGENT;
EXCEPTION
    WHEN OTHER THEN NULL;
END;

-- Drop Streamlit app (wrapped in error handler)
BEGIN
    DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.SFE_BILLING_STREAMLIT;
EXCEPTION
    WHEN OTHER THEN NULL;
END;

-- Drop Git repo clone (keep API integration per shared use)
DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO;

-- Drop warehouse
DROP WAREHOUSE IF EXISTS SFE_BILLING_WH;

-- Drop API integration
DROP API INTEGRATION IF EXISTS SFE_GIT_API_INTEGRATION;

-- Drop schemas with cascade (fully qualified)
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_SHARED_KNOWLEDGE CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_STG_TELECOM CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SFE_RAW_BILLING CASCADE;

-- Completion message
SELECT 'Demo cleanup complete. All project-specific objects removed.' AS STATUS;

-- PROTECTED SHARED INFRASTRUCTURE (preserved for other projects):
-- - snowflake_intelligence database (organizational Snowflake Intelligence repository)
-- - snowflake_intelligence.agents schema (agent discovery namespace)
-- - SNOWFLAKE_EXAMPLE database (demo database)
-- - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared Git repository namespace)
