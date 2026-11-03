-- 02 | Coverage of every event_params key, measured per EVENT (not per parameter).
-- Aggregating keys inside each event first means no made-up event_id is needed and
-- the denominator is a plain COUNT(*).
-- `once_per_event` = TRUE means the key never repeats inside the same event.
WITH per_event AS (
  SELECT
    ARRAY(
      SELECT AS STRUCT key, COUNT(*) AS n
      FROM UNNEST(event_params)
      GROUP BY key
    ) AS keys_in_event
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),
total AS (
  SELECT COUNT(*) AS total_events FROM per_event
),
agg AS (
  SELECT
    k.key AS param_key,
    COUNT(*) AS events_with_key,
    SUM(k.n) AS raw_occurrences,
    ROUND(100 * COUNT(*) / ANY_VALUE(t.total_events), 2) AS pct_coverage
  FROM per_event, UNNEST(keys_in_event) AS k, total AS t
  GROUP BY param_key
)
SELECT
  *,
  raw_occurrences = events_with_key AS once_per_event,
  CASE
    WHEN pct_coverage >= 99.9 THEN 'universal'
    WHEN pct_coverage >= 90   THEN 'near-universal'
    ELSE 'conditional'
  END AS coverage_class
FROM agg
ORDER BY events_with_key DESC;
