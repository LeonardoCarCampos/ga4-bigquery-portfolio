-- 08 | Which params does the internal-search event carry? (confirms the `search_term` key
-- used by stg_ga4__events / fct_search_terms before relying on it)
WITH per_event AS (
  SELECT
    ARRAY(SELECT DISTINCT key FROM UNNEST(event_params)) AS keys_in_event
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'view_search_results'
)
SELECT
  k AS param_key,
  COUNT(*) AS events_with_key
FROM per_event, UNNEST(keys_in_event) AS k
GROUP BY param_key
ORDER BY events_with_key DESC;
