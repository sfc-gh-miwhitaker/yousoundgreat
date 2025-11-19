/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 01_create_streams.sql
 * PURPOSE: Capture CDC for raw usage + allocation tables.
 * OBJECTS CREATED:
 *   - STREAM SFE_RAW_BILLING.USAGE_METRICS_STREAM
 *   - STREAM SFE_RAW_BILLING.COST_ALLOC_STREAM
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE STREAM SFE_RAW_BILLING.USAGE_METRICS_STREAM
    ON TABLE SFE_RAW_BILLING.USAGE_METRICS
    SHOW_INITIAL_ROWS = FALSE
    COMMENT = 'DEMO: Tracks raw usage changes for staging pipeline';

CREATE OR REPLACE STREAM SFE_RAW_BILLING.COST_ALLOC_STREAM
    ON TABLE SFE_RAW_BILLING.COST_ALLOCATIONS
    SHOW_INITIAL_ROWS = FALSE
    COMMENT = 'DEMO: Tracks cost allocation changes feeding facts';
