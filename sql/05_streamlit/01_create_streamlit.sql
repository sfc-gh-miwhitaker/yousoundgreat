/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 01_create_streamlit.sql
 * PURPOSE: Deploy Streamlit in Snowflake app sourced from Git repo stage.
 * OBJECTS CREATED:
 *   - STREAMLIT APP SFE_ANALYTICS_COSTS.SFE_BILLING_STREAMLIT
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE STREAMLIT SFE_ANALYTICS_COSTS.SFE_BILLING_STREAMLIT
    FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_BILLING_REPO/branches/main
    MAIN_FILE = 'sql/05_streamlit/app.py'
    QUERY_WAREHOUSE = SFE_BILLING_WH
    COMMENT = 'DEMO: Billing intelligence Streamlit app';
