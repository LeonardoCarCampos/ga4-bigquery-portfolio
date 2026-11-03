-- 03 | Flat events (one row per event) + reconciliation against the raw row count.
-- The two counts MUST be identical; if not, something multiplies or drops rows.
WITH flat AS (
  SELECT
    event_date,
    event_name,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')  AS page_location,
    (SELECT value.int_value    FROM UNNEST(event_params) WHERE key = 'ga_session_id')  AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),
raw AS (
  SELECT COUNT(*) AS raw_events
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT
  (SELECT COUNT(*) FROM flat)                       AS flat_events,
  raw_events,
  (SELECT COUNT(*) FROM flat) = raw_events          AS counts_match
FROM raw;
