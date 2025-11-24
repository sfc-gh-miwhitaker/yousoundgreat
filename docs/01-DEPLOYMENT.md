# 01 - Deployment Guide

## Goal
Provision the full TelecomCorp billing intelligence stack inside `SNOWFLAKE_EXAMPLE` using the ready-made Git-integrated script.

## Prerequisites
- Snowflake role with `ACCOUNTADMIN` (temporary) and `SECURITYADMIN` for grants
- Ability to create API integrations (keeps `SFE_GIT_API_INTEGRATION` for reuse)
- Snowsight worksheet access or SnowSQL (for verification queries)
- Outbound HTTPS access to `https://github.com/sfc-gh-miwhitaker/yousoundgreat`

## Steps
1. **Open Snowsight**
   - Worksheets ➜ *New Worksheet*
   - Role: `ACCOUNTADMIN`
   - Any warehouse with deployment credits
2. **Paste the deployment script**
   - In this repo, open `deploy_all.sql` in the root directory (or use the GitHub *Raw* view) and copy the entire file into the worksheet.
3. **Run All**
   - Execute the worksheet. The script automatically:
     - Ensures `SNOWFLAKE_EXAMPLE` and the `GIT_REPOS` schema exist.
     - Creates/reuses `SFE_GIT_API_INTEGRATION` and clones the GitHub repository into `SFE_BILLING_REPO`.
     - Creates `SFE_BILLING_WH`.
     - Executes each numbered SQL file via `EXECUTE IMMEDIATE FROM ...` in dependency order (setup, data, Cortex, Streamlit, cleanup).
4. **Verify objects**
   - `SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.GIT_REPOS;`
   - `SHOW STREAMLITS IN DATABASE SNOWFLAKE_EXAMPLE;`
   - `SHOW TASKS IN DATABASE SNOWFLAKE_EXAMPLE;`
   - `SHOW CORTEX SEARCH SERVICES IN SCHEMA SNOWFLAKE_EXAMPLE.SFE_SHARED_KNOWLEDGE;`
5. **Grant working roles**
   - Switch to `SECURITYADMIN` (or `SYSADMIN`) and grant the demo roles as needed (e.g., `GRANT ROLE BILLING_ANALYST_ROLE TO USER ...`).

## Expected Output
- Warehouse `SFE_BILLING_WH` (suspended)
- Schemas: `SFE_RAW_BILLING`, `SFE_STG_TELECOM`, `SFE_ANALYTICS_COSTS`, `SFE_SHARED_KNOWLEDGE`
- Pipelines: streams + tasks resumed, dynamic table `DT_ACCOUNT_BILLING`
- AI assets: Cortex ML model, search service, agent registered with Snowflake Intelligence
- Streamlit app `SFE_BILLING_STREAMLIT` referencing repo files

## Troubleshooting
- **API integration already exists**: edit `deploy_all.sql` to skip `CREATE OR REPLACE API INTEGRATION` and rerun.
- **Git repo clone failed**: confirm PAT/secret (if private) and connectivity to GitHub; re-run only the Git portion.
- **EXECUTE IMMEDIATE errors**: review `HISTORY` tab for the failing stage path and re-run specific SQL file via worksheet.
- **Tasks suspended**: rerun `ALTER TASK ... RESUME;` statements found in `sql/03_transformations/03_create_tasks.sql`.

## Next Steps
Continue to [docs/02-USAGE.md](02-USAGE.md) to operate the pipelines, Streamlit UI, and Snowflake Intelligence.
