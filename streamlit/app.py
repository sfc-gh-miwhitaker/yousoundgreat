import json
from datetime import date

import pandas as pd
import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Billing Intelligence", layout="wide")
session = get_active_session()

st.title("TelecomCorp Billing Intelligence Dashboard")
st.caption("Live metrics sourced from Snowflake dynamic tables, Cortex ML, and Cortex Search")

segment_options = [row[0] for row in session.sql(
    """
    SELECT DISTINCT segment_name
    FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
    ORDER BY segment_name
    """
).collect()]
selected_segment = st.selectbox("Segment", options=segment_options, index=0 if segment_options else None)

billing_df = session.sql(
    f"""
    SELECT billing_month, SUM(total_cost) AS total_cost
    FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
    WHERE segment_name = '{selected_segment}'
    GROUP BY billing_month
    ORDER BY billing_month
    """
).to_pandas()
billing_df.columns = [col.lower() for col in billing_df.columns]

if billing_df.empty:
    st.info("No billing data found for the selected segment yet.")
else:
    latest_row = billing_df.iloc[-1]
    st.metric("Latest Month Cost", f"${latest_row['total_cost']:,.0f}", delta=None)
    st.area_chart(billing_df.set_index("billing_month"))

anomalies_df = session.sql(
    """
    SELECT customer_name, billing_month, total_cost, avg_anomaly_score, latest_alert
    FROM SNOWFLAKE_EXAMPLE.SFE_ANALYTICS_COSTS.DT_ACCOUNT_BILLING
    WHERE latest_alert = 'ANOMALY'
    ORDER BY avg_anomaly_score DESC
    LIMIT 10
    """
).to_pandas()
anomalies_df.columns = [col.lower() for col in anomalies_df.columns]

with st.expander("Top anomaly drivers", expanded=True):
    if anomalies_df.empty:
        st.success("No anomalies detected in the current window.")
    else:
        st.dataframe(anomalies_df, hide_index=True)

st.subheader("Ask the Billing Copilot")
question = st.text_area("Question", placeholder="Which accounts exceeded budget in October?")

if st.button("Generate insight", type="primary"):
    if not question.strip():
        st.warning("Enter a question first.")
    else:
        prompt_payload = {
            "question": question.strip(),
            "as_of": date.today().isoformat(),
            "segment": selected_segment,
        }
        payload_json = json.dumps(prompt_payload)
        query = f"""
        SELECT SNOWFLAKE.CORTEX.COMPLETE(
            'snowflake-arctic',
            $$You are TelecomCorp's billing analyst assistant. Use the billing metrics table to answer questions.\nQuestion: {payload_json}$$
        ) AS ANSWER
        """
        result = session.sql(query).collect()[0][0]
        st.write(result)
