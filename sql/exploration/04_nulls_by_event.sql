-- 04 | Where are ga_session_id and page_location missing, by event_name?
-- Decides which columns can be trusted in the silver layer.
WITH flat AS (
  SELECT
    event_name,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')  AS page_location,
    (SELECT value.int_value    FROM UNNEST(event_params) WHERE key = 'ga_session_id')  AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT
  event_name,
  COUNT(*)                                   AS events,
  COUNTIF(ga_session_id IS NULL)             AS without_session_id,
  COUNTIF(page_location IS NULL)             AS without_page_location,
  ROUND(100 * COUNTIF(ga_session_id IS NULL) / COUNT(*), 2) AS pct_without_session_id
FROM flat
GROUP BY event_name
ORDER BY events DESC;
