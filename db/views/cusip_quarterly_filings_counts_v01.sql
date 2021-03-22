SELECT
  h.cusip,
  f.report_year,
  f.report_quarter,
  count(*) AS filings_count
FROM thirteen_fs f
  INNER JOIN aggregate_holdings h ON h.thirteen_f_id = f.id
GROUP BY h.cusip, f.report_year, f.report_quarter
ORDER BY h.cusip, f.report_year, f.report_quarter
