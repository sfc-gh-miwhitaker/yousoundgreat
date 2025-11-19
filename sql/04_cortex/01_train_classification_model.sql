/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 01_train_classification_model.sql
 * PURPOSE: Train Cortex ML classification model for cost anomaly detection.
 * OBJECTS CREATED:
 *   - SNOWFLAKE.ML.CLASSIFICATION SFE_ANALYTICS_COSTS.SFE_USAGE_ANOMALY_MODEL
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION SFE_ANALYTICS_COSTS.SFE_USAGE_ANOMALY_MODEL (
    INPUT_DATA => SYSTEM$REFERENCE(
        'VIEW',
        'SNOWFLAKE_EXAMPLE.SFE_STG_TELECOM.V_USAGE_ENRICHED'
    ),
    TARGET_COLNAME => 'ANOMALY_FLAG',
    CONFIG_OBJECT => OBJECT_CONSTRUCT('MAX_EPOCHS', 20, 'SHOW_EVALUATION_METRICS', TRUE)
)
COMMENT = 'DEMO: Cortex ML classification model labeling billing anomalies';
