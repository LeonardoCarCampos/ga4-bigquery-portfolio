# Design decisions and trade-offs

## 1. Flatten `event_params` with scalar subqueries, not a comma-UNNEST
`FROM events, UNNEST(event_params)` is an implicit CROSS JOIN: one row per parameter and no rows for events with an empty array. A scalar subquery keeps exactly one row per event. The same applies to `items`. Proof in `sql/exploration/07_items_unnest_pitfall.sql`; guard in `tests/assert_staging_count_matches_source.sql`.

## 2. Event key without an `event_id`
The GA4 export has no event identifier. `event_key = md5(user_pseudo_id, event_timestamp, event_name, dup_seq)` where `dup_seq` numbers events that share the first three fields. Trade-off: a plain `(user, timestamp, name)` key would silently merge colliding events and under-count; adding `dup_seq` keeps every event, and `dq_events_daily.same_timestamp_collisions` reports how often it happens.

## 3. Own sessionization
Session = `user_pseudo_id` + `ga_session_id` (`ga_session_id` is only unique per user). Events without `ga_session_id` are excluded from sessions but counted in the data-quality scorecard. Session date is the date of the first event, in `var('timezone')`.

## 4. Open vs closed funnel
- Open: sessions that fired the event, regardless of earlier steps.
- Closed: a step counts only if all earlier steps also happened.
The gap between them, plus `purchase_without_checkout` and friends, measures tagging integrity. Rates are computed after summing counts, never averaged across days.

## 5. Time between steps
First timestamp of each step per session; gaps between consecutive steps; negative gaps dropped; percentiles via `approx_quantiles` (fast, small error).

## 6. Timezone
`event_timestamp` is UTC microseconds. `06_date_vs_timestamp_timezone.sql` tests which timezone reproduces `event_date`: in this dataset it is UTC (0 mismatches; Sao Paulo 12.35%, New York 20.79%, Los Angeles 33.35%). `var('timezone')` is therefore `UTC`, so daily numbers reconcile with the export's `event_date`. Switch it to a store-local timezone only for business-day reporting, and expect day-level numbers to move.

## 7. Acquisition caveat
`traffic_source` in the GA4 BigQuery export is the user's first acquisition source, not the session's. `fct_acquisition` is therefore "by first-user source".

## 8. Retention caveat
The window starts on 2020-11-01, so the first weekly cohort includes users who already existed (left-censoring). Read the first cohort as "existing users".

## 9. Cost control
- Source is a wildcard table; every query filters `_TABLE_SUFFIX` through `var('start_date'/'end_date')`.
- Silver tables are clustered (`event_name`, `user_pseudo_id` and `session_key`) but deliberately not partitioned (see decision 12).
- Explicit column lists, never `SELECT *`.
- `scripts/dry_run.sh` before every manual query; `maximum_bytes_billed` caps every dbt query.

## 10. Medallion mapping
Bronze = the public dataset (untouched). Silver = `stg_ga4__events`, `int_ga4__sessions`. Gold = `fct_*` and `dq_events_daily`.

## 11. Known limits
Obfuscated sample, about three months, a subset of Google Merchandise Store events, no `user_id`. Findings describe this sample, not the real store.

## 12. Sandbox gotcha: do not partition historical data
In a BigQuery sandbox project (no billing), partitions expire after 60 days. This dataset is from 2020-2021, so partitioning the silver tables by `event_date` made every row expire as it was written: the model built "successfully" with 0 rows and the `unique` / `not_null` tests passed on the empty table. Only `assert_staging_count_matches_source` caught it. Fix: cluster instead of partition. With billing enabled, partitioning by date is a fine choice.

## 12. Sandbox gotcha: do not partition historical data
In a BigQuery sandbox project (no billing), partitions expire after 60 days. This dataset is from 2020-2021, so partitioning the silver tables by `event_date` made every row expire as it was written: the model built "successfully" with 0 rows and the `unique` / `not_null` tests passed on the empty table. Only `assert_staging_count_matches_source` caught it. Fix: cluster instead of partition. With billing enabled, partitioning by date is a fine choice.

## 13. Rollups and NULL: do not alias a grouped column to its own name
In `fct_step_duration`, `coalesce(device_category, 'all') AS device_category` combined with `GROUPING SETS ((device_category, step), (step))` returned NULL (not 'all') on the overall rows, because the alias shadowed the grouped column. Fix: group by a differently named column (`device`) and alias the coalesce to `device_category`. The unique-key test passed anyway; only reading the output revealed it.
