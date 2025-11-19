/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 03_create_roles.sql
 * PURPOSE: Define demo-specific RBAC roles.
 * OBJECTS CREATED:
 *   - BILLING_ANALYST_ROLE
 *   - SFE_PIPELINE_ROLE
 *   - SFE_INTELLIGENCE_ROLE
 *   - SFE_STREAMLIT_ROLE
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS BILLING_ANALYST_ROLE COMMENT = 'DEMO: Business analyst read-only role';
CREATE ROLE IF NOT EXISTS SFE_PIPELINE_ROLE COMMENT = 'DEMO: Executes tasks, streams, and dynamic tables';
CREATE ROLE IF NOT EXISTS SFE_INTELLIGENCE_ROLE COMMENT = 'DEMO: Snowflake Intelligence agent access';
CREATE ROLE IF NOT EXISTS SFE_STREAMLIT_ROLE COMMENT = 'DEMO: Streamlit in Snowflake execution role';

GRANT ROLE BILLING_ANALYST_ROLE TO ROLE SYSADMIN;
GRANT ROLE SFE_PIPELINE_ROLE TO ROLE SYSADMIN;
GRANT ROLE SFE_INTELLIGENCE_ROLE TO ROLE SYSADMIN;
GRANT ROLE SFE_STREAMLIT_ROLE TO ROLE SYSADMIN;
