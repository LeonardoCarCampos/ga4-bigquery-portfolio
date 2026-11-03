-- 05 | Which event_params keys appear MORE THAN ONCE inside a single event?
-- If a key repeats, a scalar subquery would fail (or hide a value with LIMIT 1).
-- An empty result means every key is safe to extract as a scalar.
WITH per_event AS (
  SELECT
    event_name,
    ARRAY(
      SELECT AS STRUCT key, COUNT(*) AS n
      FROM UNNEST(event_params)
      GROUP BY key
    ) AS keys_in_event
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT
  event_name,
  k.key AS param_key,
  COUNTIF(k.n > 1) AS events_where_key_repeats
FROM per_event, UNNEST(keys_in_event) AS k
GROUP BY event_name, param_key
HAVING events_where_key_repeats > 0
ORDER BY events_where_key_repeats DESC;
