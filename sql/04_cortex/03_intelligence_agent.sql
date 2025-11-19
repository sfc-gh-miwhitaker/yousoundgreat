/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 03_intelligence_agent.sql
 * PURPOSE: Provision Snowflake Intelligence agent wired to Cortex ML + Search.
 * OBJECTS CREATED:
 *   - AGENT SFE_ANALYTICS_COSTS.SFE_BILLING_AGENT
 *   - Adds agent to SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT catalog
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/
USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;

CREATE OR REPLACE AGENT SFE_ANALYTICS_COSTS.SFE_BILLING_AGENT
    PROFILE = '{"display_name": "Billing Copilot", "avatar": "spark", "color": "blue"}'
    COMMENT = 'DEMO: Telecom billing assistant using Cortex Analyst + Search'
FROM SPECIFICATION
$$
{
  "instructions": "You are TelecomCorp's billing intelligence agent. Answer questions about account costs, anomalies, and guardrails using the curated semantic dataset and billing knowledge base. Always cite the metric and month in your response.",
  "models": {
    "orchestration": "claude-3.5-sonnet",
    "reasoning": "claude-3-haiku"
  },
  "tools": [
    {
      "type": "cortex_analyst",
      "name": "account_billing_metrics",
      "database": "SNOWFLAKE_EXAMPLE",
      "schema": "SFE_ANALYTICS_COSTS",
      "object_name": "DT_ACCOUNT_BILLING",
      "description": "Monthly cost breakdown per account and segment"
    },
    {
      "type": "cortex_search",
      "name": "billing_policy_docs",
      "service_name": "SNOWFLAKE_EXAMPLE.SFE_SHARED_KNOWLEDGE.SFE_BILLING_SEARCH",
      "description": "Billing guardrails and escalation policies",
      "search_columns": ["doc_body", "doc_title"],
      "filter_columns": ["doc_type", "region_code"]
    }
  ]
}
$$;

CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
    ADD AGENT SFE_ANALYTICS_COSTS.SFE_BILLING_AGENT;
