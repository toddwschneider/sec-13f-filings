WITH most_recent AS (
  SELECT DISTINCT ON (cik)
    cik,
    name,
    city,
    state_or_country,
    date_filed AS most_recent_date_filed
  FROM thirteen_fs
  ORDER BY cik, date_filed DESC, id
),
counts AS (
  SELECT
    cik,
    count(*) AS filings_count
  FROM thirteen_fs
  GROUP BY cik
)
SELECT
  most_recent.*,
  counts.filings_count
FROM most_recent
  INNER JOIN counts ON most_recent.cik = counts.cik
