![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2025--12--21-orange)

# YouSoundGreat Billing Intelligence Demo

> **⚠️ DEMONSTRATION PROJECT - EXPIRES: 2025-12-21**  
> This demo uses Snowflake features current as of November 2025.  
> After expiration, this repository will be archived and made private.

**Author:** SE Community  
**Purpose:** Reference implementation for billing intelligence use case  
**Created:** 2025-11-21 | **Expires:** 2025-12-21 (30 days) | **Status:** ACTIVE

---

## 👋 First Time Here?
Fastest path (no local clone required):
1. **Deploy:** Copy `deploy_all.sql` from this repo, paste it into a new Snowsight worksheet (role `ACCOUNTADMIN`), and click *Run All*. Details live in `docs/01-DEPLOYMENT.md`. (~10 min)
2. **Use the demo:** Follow `docs/02-USAGE.md` to open the Streamlit app and Snowflake Intelligence agent. (~15 min)
3. **Clean up:** When finished, copy `sql/99_cleanup/teardown_all.sql` into Snowsight and run it, or follow the checklist in `docs/03-CLEANUP.md`. (~5 min)

## Overview
This repo demonstrates a billing intelligence platform built 100% natively in Snowflake. It showcases ingestion (Snowpipe Streaming), transformation (dynamic tables + tasks), AI capabilities (Cortex ML, Cortex Search, Snowflake Intelligence agents), and visualization (Streamlit in Snowflake). The platform enables natural language questions about account-level costs while maintaining governance and cost controls entirely within Snowflake.

**Snowsight-Only Mode:** This repository follows the Snowsight-only automation pattern—all workloads run directly in Snowflake. **No local Python, Node.js, or command-line tools required.** Simply copy/paste SQL into Snowsight worksheets to deploy and operate the entire platform.

## Repository Layout
- `diagrams/` – Mandatory data, flow, network, auth Mermaid diagrams (Reference Impl)
- `docs/` – Numbered guides for deployment, operations, cleanup
- `sql/` – Idempotent scripts (01 setup, 02 data, 03 transformations, 04 Cortex/Intelligence, 05 Streamlit, 99 cleanup)
- `streamlit/` – Streamlit dashboard application code
- `deploy_all.sql` – Single-script deployment (copy/paste into Snowsight)

## Key Capabilities
- Centralize billing telemetry from Kafka + Salesforce into `SNOWFLAKE_EXAMPLE`
- Maintain near-real-time aggregates via `SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING`
- Surface anomalies using `SNOWFLAKE.ML.CLASSIFICATION` and Cortex Search knowledge base
- Enable analysts to self-serve via Snowflake Intelligence agent + Streamlit dashboard

## Architecture & Compliance
All diagrams follow the mandatory Reference Impl format and are stored under `diagrams/`. Updates are tracked in `.cursor/DIAGRAM_CHANGELOG.md`. Cleanup scripts preserve shared infrastructure per demo rules (never drop `SNOWFLAKE_EXAMPLE` or shared SFE_* integrations).

## Estimated Demo Costs (Standard Edition @ $2/credit)
| Component | Consumption | Est. Credits | Est. Cost |
|-----------|-------------|--------------|-----------|
| `SFE_BILLING_WH` (XSMALL) | 15 minutes to run setup, pipelines, Streamlit refresh | 0.25 | ~$0.50 |
| Cortex ML training (`SFE_USAGE_ANOMALY_MODEL`) | Single training job | 0.10 | ~$0.20 |
| Cortex Search service (`SFE_BILLING_SEARCH`) | <0.1 GB indexed, 1 month | 0.02 | ~$0.04 |
| Snowflake Intelligence agent | Metadata only, negligible | — | $0.00 |
| **One-time total** | | **0.37 credits** | **~$0.74** |
| **Ongoing monthly (keeping pipelines idle)** | Background search storage + occasional task runs (~0.05 credits) | **0.05** | **~$0.10** |

Costs scale with data volume and warehouse runtime; adjust warehouse size or task cadence to control spend.

## Status
Production-ready reference implementation demonstrating Snowflake-native billing intelligence patterns.
