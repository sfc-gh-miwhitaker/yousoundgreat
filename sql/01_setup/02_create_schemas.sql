/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 02_create_schemas.sql
 * PURPOSE: Create SFE_* schemas for raw, staging, analytics, and shared Cortex assets.
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SFE_RAW_BILLING
 *   - SNOWFLAKE_EXAMPLE.SFE_STG_TELECOM
 *   - SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS
 *   - SNOWFLAKE_EXAMPLE.SFE_SHARED_KNOWLEDGE
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE SCHEMA IF NOT EXISTS SFE_RAW_BILLING COMMENT = 'DEMO: Raw telecom usage landing zone';
CREATE SCHEMA IF NOT EXISTS SFE_STG_TELECOM COMMENT = 'DEMO: Standardized staging zone for TelecomCorp billing data';
CREATE SCHEMA IF NOT EXISTS SFE_ANALYTICS_COSTS COMMENT = 'DEMO: Curated analytics + Cortex ML assets';
CREATE SCHEMA IF NOT EXISTS SFE_SHARED_KNOWLEDGE COMMENT = 'DEMO: Reference docs, Cortex Search indexes, semantic assets';
