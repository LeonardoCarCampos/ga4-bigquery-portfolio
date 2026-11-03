-- 01 | Events per event_name (one row per EVENT).
-- Lesson: do NOT put UNNEST(items) in FROM here. It is an implicit CROSS JOIN: it multiplies
-- events by their item count and drops events with no items (page_view, session_start...).
-- See 07_items_unnest_pitfall.sql for the side-by-side proof.
SELECT
  event_name,
  COUNT(*) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY event_name
ORDER BY events DESC;
