WITH holding_counts AS (
  SELECT
    cusip,
    issuer_name,
    class_title,
    shares_or_principal_amount_type,
    count(*) AS holdings_count
  FROM aggregate_holdings
  GROUP BY cusip, issuer_name, class_title, shares_or_principal_amount_type
)
SELECT DISTINCT ON (cusip) *
FROM holding_counts
ORDER BY cusip, holdings_count DESC, issuer_name, class_title
