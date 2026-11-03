-- 07 | The UNNEST(items) pitfall, side by side.
-- correct_events : one row per event (what we want when counting events)
-- inflated_rows  : FROM table, UNNEST(items) = one row per ITEM, events without items vanish
-- Run this once and screenshot it for the README: it explains many "two numbers for the same
-- event" divergences (a join or unnest that silently changes the grain of the table).
WITH correct AS (
  SELECT event_name, COUNT(*) AS correct_events
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY event_name
),
inflated AS (
  SELECT event_name, COUNT(*) AS inflated_rows
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY event_name
)
SELECT
  c.event_name,
  c.correct_events,
  COALESCE(i.inflated_rows, 0) AS inflated_rows,
  ROUND(SAFE_DIVIDE(COALESCE(i.inflated_rows, 0), c.correct_events), 2) AS inflation_ratio
FROM correct AS c
LEFT JOIN inflated AS i USING (event_name)
ORDER BY c.correct_events DESC;
