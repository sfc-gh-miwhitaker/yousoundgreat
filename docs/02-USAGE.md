# 02 - Usage & Demo Script

## Goal
Operate the end-to-end billing demo: refresh data, inspect anomalies, and present AI-driven insights.

## Prerequisites
- Deployment completed (`docs/01-DEPLOYMENT.md`)
- Snowflake roles granted to your user:
  - `BILLING_ANALYST_ROLE` for dashboards and Streamlit
  - `SFE_INTELLIGENCE_ROLE` for the agent (Snowsight handles this automatically)
  - `SFE_PIPELINE_ROLE` only if you plan to run manual SQL against tasks/streams

## Run the demo (Snowsight only)
1. **Streamlit dashboard**
   - Snowsight → Projects → Streamlit → `SFE_BILLING_STREAMLIT`
   - Select a customer segment to populate the KPI card and area chart.
   - Use the *Top anomaly drivers* table to narrate Cortex ML alerts.
   - In *Ask the Billing Copilot*, type a natural-language billing question and click **Generate insight**.
2. **Snowflake Intelligence agent**
   - Snowsight → AI & ML → Intelligence → Billing Copilot
   - Example prompts:
     - “Show the highest cost customers this month.”
     - “Summarize anomaly alerts by segment.”
     - “What escalation policy covers LATAM accounts?”
   - Point out how answers cite both structured facts (dynamic table) and document guidance (Cortex Search).

## Pipeline maintenance (if needed)
- **Usage → Staging:** Task `SFE_PIPELINE_USAGE_TO_STG` consumes `USAGE_METRICS_STREAM`. Force a refresh with `CALL SYSTEM$TASK_FORCE_RUN('SFE_STG_TELECOM.SFE_PIPELINE_USAGE_TO_STG');`.
- **Staging → Fact:** Task `SFE_PIPELINE_STG_TO_FACT` keeps `FCT_ACCOUNT_COSTS` current and feeds the dynamic table.
- **Manual data reload:** Re-run `sql/02_data/02_load_sample_data.sql` from Snowsight (role `SYSADMIN`) for fresh synthetic data.

## Refresh Pipelines
- **Usage → Staging**: `SFE_PIPELINE_USAGE_TO_STG` task listens to `USAGE_METRICS_STREAM`. Use `CALL SYSTEM$TASK_FORCE_RUN(...)` if you need an immediate refresh.
- **Staging → Fact**: `SFE_PIPELINE_STG_TO_FACT` hydrates `FCT_ACCOUNT_COSTS` and powers the dynamic table.
- **Manual data reload**: Re-run `sql/02_data/02_load_sample_data.sql` from Snowsight (role `SYSADMIN`) for fresh synthetic data.

## Validation Queries
- View dynamic table freshness: `SELECT * FROM SNOWFLAKE_EXAMPLE.INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY WHERE TABLE_NAME = 'DT_ACCOUNT_BILLING';`
- Inspect Cortex model status: `SHOW SNOWFLAKE.ML.CLASSIFICATION LIKE 'SFE_USAGE_ANOMALY_MODEL';`
- Check search service lag: `DESCRIBE CORTEX SEARCH SERVICE SFE_SHARED_KNOWLEDGE.SFE_BILLING_SEARCH;`

## Troubleshooting
- **Streamlit blank**: In Snowsight, refresh the Streamlit app (ellipsis menu → *Reboot*). Ensure `SFE_BILLING_WH` is resumed.
- **Agent missing**: Re-run `sql/04_cortex/03_intelligence_agent.sql` to recreate and register the agent, then refresh the Snowflake Intelligence settings page.
- **Tasks suspended**: `SHOW TASKS IN DATABASE SNOWFLAKE_EXAMPLE;` and `ALTER TASK … RESUME;` as needed.

## Next Steps
After the session, follow [docs/03-CLEANUP.md](03-CLEANUP.md) to retire demo-specific objects while keeping shared infrastructure intact.
