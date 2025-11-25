/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: deploy_all.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * SNOWSIGHT USAGE:
 *   1. Copy this entire script.
 *   2. Open Snowsight -> Worksheets -> New Worksheet.
 *   3. Set role ACCOUNTADMIN and warehouse with appropriate credits.
 *   4. Paste and click "Run All" (~10 minutes runtime).
 *
 * REQUIREMENTS:
 *   - ACCOUNTADMIN rights to create API integrations and warehouses.
 *   - Outbound HTTPS access to GitHub.
 *   - Target repo: https://github.com/sfc-gh-miwhitaker/yousoundgreat
 *
 * ORDER OF OPERATIONS:
 *   1. Create/reuse SNOWFLAKE_EXAMPLE database + shared schemas.
 *   2. Create API integration + Git repository referencing GitHub.
 *   3. Create dedicated warehouse SFE_BILLING_WH (auto-suspend 60s).
 *   4. Execute numbered SQL scripts directly from the Git repo stage.
 * 
 * TROUBLESHOOTING:
 *   - If API integration already exists, comment out the CREATE statement.
 *   - Use SHOW GIT REPOSITORIES to confirm clone succeeded.
 *   - Refer to docs/01-DEPLOYMENT.md for additional steps.
 ******************************************************************************/

-- Expiration Check -----------------------------------------------------------
-- This demo expires on 2025-12-21 (30 days from creation: 2025-11-21)
DECLARE
    expiration_date DATE := '2025-12-21';
    current_date DATE := CURRENT_DATE();
    days_remaining INT;
BEGIN
    days_remaining := DATEDIFF('day', current_date, expiration_date);
    
    IF (current_date > expiration_date) THEN
        RAISE EXCEPTION 'DEMO EXPIRED: This demo expired on 2025-12-21. Code may reference outdated Snowflake syntax or deprecated features. Please check for updated versions or contact SE Community.';
    ELSIF (days_remaining <= 7) THEN
        CALL SYSTEM$LOG('WARNING', 'DEMO EXPIRING SOON: This demo expires in ' || days_remaining || ' days on 2025-12-21.');
    ELSE
        CALL SYSTEM$LOG('INFO', 'Demo is active. ' || days_remaining || ' days remaining until expiration on 2025-12-21.');
    END IF;
END;

-- Context --------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

-- Create shared infrastructure (owned by SYSADMIN for demo project use)
USE ROLE SYSADMIN;
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE COMMENT = 'Demo/Example projects - NOT FOR PRODUCTION';
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS COMMENT = 'DEMO: Shared Git repository stage area (Expires: 2025-12-21)';

-- Switch back to ACCOUNTADMIN for API integration and Git repo creation
USE ROLE ACCOUNTADMIN;

-- API Integration -------------------------------------------------------------
CREATE OR REPLACE API INTEGRATION SFE_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-miwhitaker/yousoundgreat.git')
    ENABLED = TRUE
    COMMENT = 'DEMO: Billing intelligence repo integration (Expires: 2025-12-21)';

-- Git Repository --------------------------------------------------------------
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO
    API_INTEGRATION = SFE_GIT_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/yousoundgreat.git'
    COMMENT = 'DEMO: Git reference for billing intelligence demo (Expires: 2025-12-21)';


-- Fetch Repository Contents --------------------------------------------------
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO FETCH;

-- Warehouse ------------------------------------------------------------------
CREATE OR REPLACE WAREHOUSE SFE_BILLING_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: Dedicated warehouse for billing intelligence workloads (Expires: 2025-12-21)';

USE WAREHOUSE SFE_BILLING_WH;

-- Execute numbered scripts from Git repository stage --------------------------
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/01_setup/01_create_database.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/01_setup/02_create_schemas.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/01_setup/03_create_roles.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/01_setup/04_grants.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/02_data/01_create_tables.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/02_data/02_load_sample_data.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/03_transformations/01_create_streams.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/03_transformations/02_create_views.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/03_transformations/03_create_semantic_view.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/03_transformations/04_create_tasks.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/04_cortex/01_train_classification_model.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/04_cortex/02_cortex_search.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/04_cortex/03_intelligence_agent.sql';
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main/sql/05_streamlit/01_create_streamlit.sql';

-- Completion banner -----------------------------------------------------------
SELECT 'Billing intelligence demo deployment complete. Switch to BILLING_ANALYST_ROLE for day-two operations.' AS STATUS_MESSAGE;
