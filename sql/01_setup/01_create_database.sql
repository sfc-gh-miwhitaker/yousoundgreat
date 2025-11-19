/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 01_create_database.sql
 * PURPOSE: Ensure SNOWFLAKE_EXAMPLE database + shared schemas exist.
 * OBJECTS CREATED:
 *   - Database SNOWFLAKE_EXAMPLE (if missing)
 *   - Schema SNOWFLAKE_EXAMPLE.GIT_REPOS (for Git clones)
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Repository for example projects - NOT FOR PRODUCTION';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS
    COMMENT = 'DEMO: Holds Git repository clones for billing intelligence demo';
