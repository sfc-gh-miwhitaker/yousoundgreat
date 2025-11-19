/*******************************************************************************
 * DEMO PROJECT: YouSoundGreat Billing Intelligence
 * Script: 03_intelligence_agent.sql
 * PURPOSE: Provision production-grade Snowflake Intelligence agent with
 *          comprehensive instructions, tool integration, and governance controls.
 * 
 * OBJECTS CREATED:
 *   - DATABASE snowflake_intelligence (if not exists)
 *   - SCHEMA snowflake_intelligence.agents (if not exists)
 *   - AGENT snowflake_intelligence.agents.SFE_BILLING_AGENT
 * 
 * AGENT CAPABILITIES:
 *   - Cortex Analyst: Queries semantic Dynamic Table for structured billing data
 *   - Cortex Search: Retrieves unstructured policy documents and knowledge base
 *   - Orchestration: Claude 3.5 Sonnet with token/time budgets
 * 
 * ACCESS CONTROL:
 *   - Requires CORTEX_AGENT_USER database role
 *   - USAGE privilege on agent object for execution
 *   - MONITOR privilege for observability access
 * 
 * DISCOVERABILITY:
 *   - Agent appears in Snowsight -> Snowflake Intelligence -> Agents UI
 *   - Accessible via REST API: /api/v2/databases/snowflake_intelligence/schemas/agents/agents/SFE_BILLING_AGENT
 * 
 * CLEANUP: sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

-- Step 1: Create snowflake_intelligence database and agents schema (Snowflake standard location)
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS snowflake_intelligence
    COMMENT = 'Snowflake Intelligence: Central repository for Cortex Agents and AI objects';
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;

CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents
    COMMENT = 'Snowflake Intelligence: Agent discovery schema - agents here appear in Snowsight UI';
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;
GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE SYSADMIN;

-- Step 2: Create Snowflake Intelligence agent in standard discovery location
USE ROLE SYSADMIN;
USE DATABASE snowflake_intelligence;

-- Create agent in Snowflake Intelligence agents schema for UI discoverability
CREATE OR REPLACE AGENT agents.SFE_BILLING_AGENT
    PROFILE = '{"display_name": "Billing Intelligence Copilot", "avatar": "spark", "color": "blue"}'
    COMMENT = 'DEMO: Production-grade telecom billing assistant with governed semantic data access and policy knowledge base integration'
FROM SPECIFICATION
$$
{
  "instructions": {
    "system": "You are the Billing Intelligence Copilot for YouSoundGreat telecommunications. Your role is to help analysts understand account costs, identify billing anomalies, and retrieve escalation policies.\n\n**Scope & Boundaries:**\n- You MAY answer questions about account-level costs, usage patterns, segment trends, and billing guardrails.\n- You MUST NOT expose raw customer PII, credentials, or internal system identifiers.\n- You MUST disclose when data is stale or missing; always cite the data freshness timestamp.\n- You MUST refuse requests for actions outside your read-only analytical scope (e.g., 'update account', 'process refund').\n\n**Data Classification:**\n- All cost data is internal-use only; responses should not be shared externally without review.\n- Policy documents may contain sensitive escalation contacts; redact phone numbers and emails unless explicitly requested by authorized roles.\n\n**Reference Impl Warning:**\nThis is a DEMO agent for reference architecture purposes. Review and customize instructions, tool permissions, and data access for your organization's specific requirements before production deployment.",
    
    "orchestration": "**Tool Selection Strategy:**\n1. For quantitative questions about costs, usage, accounts, or time-series trends → use `account_billing_metrics` (Cortex Analyst on semantic Dynamic Table).\n2. For policy lookups, guardrail definitions, escalation procedures, or unstructured documentation → use `billing_policy_docs` (Cortex Search).\n3. Always produce a brief step plan before executing tools.\n4. Reuse previous tool results within the same conversation instead of re-querying.\n5. Verify tool outcomes are non-empty before citing them; if empty, state 'No data found for <criteria>' and suggest broadening the query.\n\n**Data Governance:**\n- ONLY query the semantic Dynamic Table `DT_ACCOUNT_BILLING` through Cortex Analyst; NEVER attempt direct SQL against RAW_BILLING or staging schemas.\n- Reference semantic view names in your response (e.g., 'Sourced from DT_ACCOUNT_BILLING') for traceability.\n- If SQL generation fails, explain the error in plain language and suggest alternative queries.\n\n**Warehouse & Performance:**\n- Analyst queries execute on SFE_BILLING_WH (X-SMALL); keep queries selective to avoid long runtimes.\n- If you anticipate a heavy aggregation, warn the user and suggest filtering by date range or segment.\n\n**Fallback Behavior:**\n- If Cortex Analyst returns an error, attempt to rephrase the SQL or suggest manual investigation.\n- If Cortex Search returns no documents, recommend checking document freshness or contacting the knowledge base owner.\n- For out-of-scope questions (e.g., 'book a meeting', 'access production systems'), politely decline and recommend human escalation.",
    
    "response": "**Formatting Rules:**\n- Use Markdown with clear section headers (## Summary, ## Data, ## Sources).\n- Present numeric data in tables when comparing multiple accounts or time periods.\n- Always include:\n  * Data freshness timestamp (e.g., 'Data as of 2025-11-15 08:00 UTC')\n  * Semantic view or search service name used\n  * SQL snippet (in code block) if Cortex Analyst was invoked\n- Round currency to 2 decimals; show percentages to 1 decimal.\n- For anomalies, highlight the deviation magnitude (e.g., '+150% vs. prior month').\n\n**Citations & Transparency:**\n- Cite the tool and data source for every factual claim (e.g., '[Source: DT_ACCOUNT_BILLING, 2025-11]').\n- If confidence is low, include a caveat: 'This analysis is based on limited data; verify with manual review.'\n- When citing policy documents, include document title and type (e.g., '[Policy: Billing Escalation SOP, doc_type=GUARDRAIL]').\n\n**Redaction & Privacy:**\n- Mask account IDs beyond the first 4 digits (e.g., '1234****').\n- Truncate long JSON payloads to first 200 chars with '...'.\n- Never display raw customer names, emails, or phone numbers unless explicitly requested by BILLING_ADMIN role.\n\n**Escalation Guidance:**\n- If the user asks about manual refunds, credit adjustments, or account modifications, respond: 'I cannot perform account modifications. Please escalate to the Billing Operations team via [escalation procedure from policy docs].'\n\n**Sample Interactions for Reference:**\nExample 1 (Top Accounts): 'What were the top 5 accounts by cost in November 2024?' → account_billing_metrics → WHERE billing_month = '2024-11-01' ORDER BY total_cost DESC LIMIT 5 → Return: account_id, customer_name, segment_name, costs\nExample 2 (Anomalies): 'Show me accounts with anomalies this month' → account_billing_metrics → WHERE latest_alert = 'ANOMALY' AND billing_month = current → Sort by avg_anomaly_score DESC\nExample 3 (Segment Compare): 'Compare Enterprise vs SMB vs Commercial, last 3 months' → account_billing_metrics → Group by segment_name, billing_month → Return time-series: segment, month, avg_cost, count\nExample 4 (Account Detail): 'Costs for account 12345 in October 2024?' → account_billing_metrics → WHERE account_id = 12345 AND billing_month = '2024-10-01' → voice/data/sms breakdown with %\nExample 5 (MoM Growth): 'Accounts with cost increases >20% month-over-month?' → account_billing_metrics → LAG window function → WHERE pct_change > 20% ORDER BY pct_change DESC\nExample 6 (Trend): 'Enterprise cost trend, last 6 months' → account_billing_metrics → WHERE segment = 'Enterprise' for 6 months → Group by month → totals, averages, counts\nExample 7 (Policy): 'Escalation policy for billing disputes over $10,000?' → billing_policy_docs filter doc_type='GUARDRAIL' → Search: escalation, threshold → Cite doc title, excerpt\nExample 8 (Refusal): 'Process refund for account 12345?' → REFUSE: Cannot modify accounts → Then retrieve Refund Policy via billing_policy_docs → Provide escalation steps\n\nNote: Examples 1-6 validated in sql/03_transformations/02_create_views.sql"
  },
  
  "models": {
    "orchestration": "claude-3.5-sonnet"
  },
  
  "orchestration": {
    "budget": {
      "seconds": 45,
      "tokens": 20000
    }
  },
  
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "account_billing_metrics",
        "description": "**Primary Purpose:** Generate and execute SQL queries against the curated semantic Dynamic Table `DT_ACCOUNT_BILLING` to retrieve quantitative billing metrics and cost analytics.\n\n**When to Use This Tool:**\n- User asks for numeric data: costs, counts, averages, totals, percentages\n- Questions about specific accounts, time periods, or segments\n- Comparative analysis (month-over-month, segment-over-segment)\n- Anomaly detection and threshold violations\n- Time-series trends and historical patterns\n- Aggregations and groupings (sum, avg, count by dimension)\n\n**Available Data Dimensions:**\n- Account identifiers: account_id, customer_name\n- Time dimensions: billing_month, year, quarter\n- Segments: segment_name (Enterprise, Commercial, SMB)\n- Cost metrics: total_cost, avg_cost, cost_variance_pct\n- Usage metrics: minutes_used, data_mb, sms_count\n- Quality indicators: anomaly_flag, cost_bucket, data_freshness_ts\n- Geographic: region_code (NAMER, EMEA, APAC, LATAM)\n\n**Output Format:** Returns structured tabular data with columns matching the semantic model. Results are row-based and suitable for direct presentation in tables or further analysis.\n\n**Performance Characteristics:**\n- Executes on SFE_BILLING_WH (X-SMALL warehouse)\n- Query timeout: 120 seconds\n- Optimized for queries returning <10K rows\n- Underlying table contains ~5K sample accounts with 12 months of history\n\n**Limitations:**\n- Read-only access (cannot INSERT, UPDATE, DELETE)\n- No access to raw schemas (RAW_BILLING, STG_TELECOM)\n- Cannot create temp tables or procedures\n- No cross-database joins outside semantic view\n\n**Example Use Cases:**\n- 'What were total costs for account 12345 in November 2025?'\n- 'Show top 10 accounts by spend this quarter'\n- 'Which Enterprise segment accounts have anomalies this month?'\n- 'Compare average costs: SMB vs Enterprise, last 3 months'\n- 'List accounts with cost increases >20% month-over-month'"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "billing_policy_docs",
        "description": "**Primary Purpose:** Perform semantic search over unstructured billing documentation to retrieve relevant policy excerpts, procedural guidance, escalation paths, and knowledge base articles.\n\n**When to Use This Tool:**\n- User asks about policies, procedures, rules, or guidelines\n- Questions about 'how to handle', 'what is the policy for', 'who to escalate to'\n- Qualitative information needs (not numeric data)\n- Compliance requirements and regulatory guidance\n- Process documentation and standard operating procedures\n- Troubleshooting steps and FAQ content\n- Contact information and escalation hierarchies\n\n**Document Collection Scope:**\n- Policy documents: Billing policies, credit policies, refund policies\n- Guardrails: Spending thresholds, approval requirements, credit limits\n- Escalation procedures: When to escalate, who to contact, SLA timelines\n- FAQs: Common billing questions and answers\n- Compliance: Regulatory requirements, audit procedures\n- Knowledge base: Best practices, troubleshooting guides, case studies\n\n**Search Capabilities:**\n- Semantic similarity matching (finds conceptually related content)\n- Multi-column search: Searches both `doc_title` and `doc_body` fields\n- Filtering: Narrow results by `doc_type` (POLICY, GUARDRAIL, FAQ, COMPLIANCE) and `region_code` (NAMER, EMEA, APAC, LATAM)\n- Max results: Returns up to 10 most relevant documents per query\n- Ranking: Results ordered by semantic relevance score\n\n**Output Format:** Returns document excerpts with metadata:\n- doc_title: Document name\n- doc_body: Relevant text excerpt (may be partial)\n- doc_type: Document category\n- region_code: Geographic applicability\n- relevance_score: Similarity score (0-1, higher = more relevant)\n\n**Performance Characteristics:**\n- Typically returns results in <3 seconds\n- Collection contains ~500 policy documents\n- Documents updated quarterly (check doc_last_updated field)\n- Embedding model: Multi-lingual text embedding v1\n\n**Limitations:**\n- Cannot create or update documents\n- Search is read-only\n- No support for complex boolean queries (AND/OR/NOT)\n- Filter values must match exactly (case-sensitive)\n- May not find content if query phrasing differs significantly from document language\n\n**Example Use Cases:**\n- 'What is the escalation policy for billing disputes over $10,000?'\n- 'How do we handle refund requests for Enterprise accounts?'\n- 'What are the credit approval thresholds by segment?'\n- 'Who do I contact for urgent billing issues in EMEA?'\n- 'What is our policy on late payment fees?'\n- 'Find all guardrails related to high-value accounts'\n\n**Search Strategy Tips:**\n- Use specific keywords from policy domain (e.g., 'escalation', 'threshold', 'approval')\n- Phrase questions naturally (semantic search understands intent)\n- Apply filters when region or document type is known\n- If initial search returns no results, try rephrasing with synonyms"
      }
    }
  ],
  
  "tool_resources": {
    "account_billing_metrics": {
      "semantic_view": "SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.SV_ACCOUNT_BILLING",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "SFE_BILLING_WH",
        "query_timeout": 120
      }
    },
    "billing_policy_docs": {
      "name": "SNOWFLAKE_EXAMPLE.SFE_SHARED_KNOWLEDGE.SFE_BILLING_SEARCH",
      "max_results": 10,
      "search_columns": ["doc_body", "doc_title"],
      "filter_columns": ["doc_type", "region_code"]
    }
  }
}
$$;

-- Agent successfully created in Snowflake Intelligence standard location
-- Discoverable via: Snowsight UI -> Snowflake Intelligence -> Agents
-- REST API path: /api/v2/databases/snowflake_intelligence/schemas/agents/agents/SFE_BILLING_AGENT
