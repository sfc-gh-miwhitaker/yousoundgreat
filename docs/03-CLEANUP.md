# 03 - Cleanup

## Goal
Remove all demo-created objects while preserving `SNOWFLAKE_EXAMPLE` and shared integrations (`SFE_GIT_API_INTEGRATION`).

## Prerequisites
- `ACCOUNTADMIN` role
- No running demos (stop Streamlit sessions and ensure tasks can be suspended)

## Steps
1. **Suspend tasks**
   - Optional but recommended: `ALTER TASK SFE_STG_TELECOM.SFE_PIPELINE_USAGE_TO_STG SUSPEND;`
2. **Run cleanup script**
   - Snowsight → Worksheets (role `ACCOUNTADMIN`)
   - Copy the contents of `sql/99_cleanup/teardown_all.sql` from this repo, paste into the worksheet, and click *Run All*.
3. **Verify removals**
   - `SHOW SCHEMAS LIKE 'SFE_%' IN DATABASE SNOWFLAKE_EXAMPLE;` (should return none)
   - `SHOW STREAMLITS IN DATABASE SNOWFLAKE_EXAMPLE;` (should be empty)
   - `SHOW WAREHOUSES LIKE 'SFE_BILLING_WH';` (should be empty)
   - `SHOW AGENTS LIKE 'SFE_BILLING_AGENT';` (should be empty)
4. **Optionally drop Git repo**
   - Already handled in script (`SFE_BILLING_REPO`). Ensure `SFE_GIT_API_INTEGRATION` remains for other projects.

## Expected Output
- Schemas `SFE_RAW_BILLING`, `SFE_STG_TELECOM`, `SFE_ANALYTICS_COSTS`, `SFE_SHARED_KNOWLEDGE` dropped
- Warehouse `SFE_BILLING_WH` removed
- Git repo clone, Streamlit app, Cortex resources, tasks, streams, agent removed
- `SNOWFLAKE_EXAMPLE` database untouched, API integration preserved

## Troubleshooting
- **Object still in use**: Ensure no running queries reference the schema; re-run cleanup after stopping dependent sessions.
- **Agent removal fails**: Run `ALTER SNOWFLAKE INTELLIGENCE ... DROP AGENT` manually, then `DROP AGENT`.
- **Warehouse drop blocked**: Resume and suspend `SFE_BILLING_WH` before dropping if necessary.

## Next Steps
Re-run `docs/01-DEPLOYMENT.md` whenever you need to reprovision the environment.
