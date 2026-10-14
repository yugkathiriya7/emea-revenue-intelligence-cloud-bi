

  SELECT
    COUNT(*) AS total_invoices,
    ROUND(SUM(revenue_eur), 2) AS total_revenue_eur
FROM
    `emea-strategic-analytics.emea_analytics.fact_revenue`;

    


SELECT *
FROM
  `emea-strategic-analytics.emea_analytics.raw_ibp_plan`
LIMIT 10;



SELECT
  account_id,
  resolved_customer_name AS account_name,
  home_cluster AS cluster,
  FORMAT_DATE('%Y-%m', invoice_date) AS revenue_month,
  COUNT(DISTINCT invoice_id) AS total_invoices,
  ROUND(SUM(revenue_eur), 2) AS actual_revenue_eur
FROM
  `emea-strategic-analytics.emea_analytics.fact_revenue`
GROUP BY
  account_id,
  account_name,
  cluster,
  revenue_month
ORDER BY
  revenue_month,
  account_name;



SELECT
  column_name,
  data_type
FROM
  `emea-strategic-analytics.emea_analytics.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'raw_ibp_plan'
ORDER BY ordinal_position;



SELECT
  plan_month,
  account_id,
  scenario,
  COUNT(*) AS record_count
FROM
  `emea-strategic-analytics.emea_analytics.raw_ibp_plan`
WHERE scenario = 'Base'
GROUP BY
  plan_month, account_id, scenario
HAVING COUNT(*) > 1;




CREATE OR REPLACE TABLE
`emea-strategic-analytics.emea_analytics.mart_account_performance`
AS

WITH actuals AS (
  SELECT
    account_id,
    FORMAT_DATE('%Y-%m', invoice_date) AS report_month,
    COUNT(DISTINCT invoice_id) AS total_invoices,
    SUM(quantity) AS actual_units,
    ROUND(SUM(revenue_eur), 2) AS actual_revenue_eur
  FROM
    `emea-strategic-analytics.emea_analytics.fact_revenue`
  GROUP BY account_id, report_month
),

plans AS (
  SELECT
    account_id,
    plan_month AS report_month,
    SUM(planned_revenue_eur) AS planned_revenue_eur,
    SUM(forecast_revenue_eur) AS forecast_revenue_eur,
    SUM(planned_units) AS planned_units
  FROM
    `emea-strategic-analytics.emea_analytics.raw_ibp_plan`
  WHERE scenario = 'Base'
  GROUP BY account_id, report_month
),

combined AS (
  SELECT
    COALESCE(a.account_id, p.account_id) AS account_id,
    COALESCE(a.report_month, p.report_month) AS report_month,
    a.total_invoices,
    a.actual_units,
    a.actual_revenue_eur,
    p.planned_revenue_eur,
    p.forecast_revenue_eur,
    p.planned_units
  FROM actuals a
  FULL OUTER JOIN plans p
    ON a.account_id = p.account_id
   AND a.report_month = p.report_month
)

SELECT
  c.report_month,
  c.account_id,
  m.canonical_account_name AS account_name,
  m.home_cluster AS cluster,
  c.total_invoices,
  c.actual_units,
  c.planned_units,
  c.actual_revenue_eur,
  c.planned_revenue_eur,
  c.forecast_revenue_eur,

  ROUND(
    c.actual_revenue_eur - c.planned_revenue_eur,
    2
  ) AS gap_to_plan_eur,

  ROUND(
    SAFE_DIVIDE(
      c.actual_revenue_eur,
      c.planned_revenue_eur
    ) * 100,
    2
  ) AS attainment_pct,

  ROUND(
    c.forecast_revenue_eur - c.actual_revenue_eur,
    2
  ) AS forecast_bias_eur

FROM combined c
LEFT JOIN
  `emea-strategic-analytics.emea_analytics.account_master` m
  ON c.account_id = m.account_id;


SELECT
  report_month,
  account_name,
  cluster,
  actual_revenue_eur,
  planned_revenue_eur,
  gap_to_plan_eur,
  attainment_pct,
  forecast_bias_eur
FROM
  `emea-strategic-analytics.emea_analytics.mart_account_performance`
ORDER BY report_month, account_name
LIMIT 20;



SELECT *
FROM
  `emea-strategic-analytics.emea_analytics.mart_account_performance`
ORDER BY report_month, account_name;


