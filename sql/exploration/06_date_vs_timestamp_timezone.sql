-- 06 | event_date (export, property timezone) vs the date of event_timestamp (UTC micros)
-- converted to different timezones. The timezone with ~0 mismatches is the property's timezone.
-- This is the same class of bug as "day X has different totals in two tools".
SELECT
  tz,
  COUNT(*) AS events,
  COUNTIF(
    event_date != FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(event_timestamp), tz))
  ) AS mismatches,
  ROUND(100 * COUNTIF(
    event_date != FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(event_timestamp), tz))
  ) / COUNT(*), 2) AS pct_mismatch
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(['UTC', 'America/Los_Angeles', 'America/New_York', 'America/Sao_Paulo']) AS tz
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY tz
ORDER BY mismatches;
