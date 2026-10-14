
-- Data-quality checks for raw ERP invoices

-- 1. Identify duplicate invoice IDs
SELECT
  invoice_id,
  COUNT(*) AS occurrence_count
FROM `emea-strategic-analytics.emea_analytics.raw_erp_billing`
GROUP BY invoice_id
HAVING COUNT(*) > 1;

-- 2. Check currency distribution
SELECT
  currency,
  COUNT(*) AS record_count
FROM `emea-strategic-analytics.emea_analytics.raw_erp_billing`
GROUP BY currency
ORDER BY record_count DESC;

-- 3. Check rejected invoice reasons
SELECT
  rejection_reason,
  COUNT(*) AS rejected_count
FROM `emea-strategic-analytics.emea_analytics.rejected_records`
GROUP BY rejection_reason;

-- 4. Reconcile loaded revenue
SELECT
  COUNT(*) AS accepted_invoices,
  ROUND(SUM(revenue_eur), 2) AS validated_revenue_eur
FROM `emea-strategic-analytics.emea_analytics.fact_revenue`;
