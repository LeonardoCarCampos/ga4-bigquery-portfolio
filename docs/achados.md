# Findings

Period: 2020-11-01 to 2021-01-31 · Timezone: UTC (matches `event_date`, see 7) · Source: public GA4 sample, obfuscated, about 3 months.

## 1. Dataset sanity
- 4,295,584 events, 17 distinct event names, 360,129 sessions (own sessionization: `user_pseudo_id` + `ga_session_id`).
- Flat events (scalar subqueries) reconcile with the raw row count; staging equals source in `assert_staging_count_matches_source`.

## 2. The UNNEST(items) pitfall
| event_name | correct_events | inflated_rows | inflation_ratio |
|---|---|---|---|
| view_item | 386,068 | 2,748,246 | 7.12 |
| add_to_cart | 58,543 | 667,426 | 11.40 |
| select_item | 31,007 | 329,364 | 10.62 |
| purchase | 5,692 | 16,003 | 2.81 |
| begin_checkout | 38,757 | 77,980 | 2.01 |
| view_item_list | 71 | 516 | 7.27 |
| view_promotion | 190,104 | 134,602 | 0.71 |
| select_promotion | 9,450 | 8,595 | 0.91 |
| page_view, session_start, user_engagement, scroll, first_visit, view_search_results, add_shipping_info, add_payment_info, click | all counts | 0 | 0 |

Takeaway: a comma-UNNEST changes the grain. Counts inflate for events with several items, shrink for events with few, and events without items vanish.

## 3. Funnel
Closed funnel (a step counts only if every earlier step occurred in the session):

| step | sessions | % of previous | % of first |
|---|---|---|---|
| view_item | 77,020 | | 100.0% |
| add_to_cart | 15,173 | 19.7% | 19.7% |
| begin_checkout | 5,959 | 39.3% | 7.7% |
| add_shipping_info | 5,959 | 100.0% | 7.7% |
| add_payment_info | 3,858 | 64.7% | 5.0% |
| purchase | 2,848 | 73.8% | 3.7% |

- Biggest drops: `view_item` to `add_to_cart` (80.3% leave) and `add_shipping_info` to `add_payment_info` (35.3% leave).
- Open funnel: 11,106 sessions start checkout (closed: 5,959) and 4,848 sessions purchase (closed: 2,848). Session conversion over all sessions: 4,848 / 360,129 = 1.35%.
- Event level vs session level: `begin_checkout` to `purchase` is 14.7% by events and 47.8% by closed-funnel sessions (about 3.5 `begin_checkout` events per session).

Paths of the 4,848 purchase sessions:

| view_item | add_to_cart | begin_checkout | shipping | payment | sessions |
|---|---|---|---|---|---|
| yes | yes | yes | yes | yes | 2,848 |
| yes | no | yes | yes | yes | 1,849 |
| no | no | yes | yes | yes | 147 |
| no | no | no | no | no | 3 |
| yes | no | yes | no | yes | 1 |

All 2,000 purchase sessions outside the closed funnel lack `add_to_cart`.

## 4. Open questions on tagging
- 5,145 of 11,106 checkout sessions have no `add_to_cart`; only 379 of them had a cart in an earlier session. Not explained: a checkout path without `add_to_cart`, or missing tagging.
- 657 sessions have `add_to_cart` only after `begin_checkout`.
- `add_shipping_info` fires in 11,086 of 11,106 checkout sessions, a median 0 s after `begin_checkout`.
- `view_item_list`: 71 events versus 31,007 `select_item`.

## 5. Time between steps
Median / p90 seconds, measured pairwise (sessions that have both events of the pair, so session counts are not a funnel):

| step | sessions measured | median | p90 |
|---|---|---|---|
| view_item to add_to_cart | 15,147 | 12 | 464 |
| add_to_cart to begin_checkout | 5,304 | 256 | 1,377 |
| begin_checkout to add_shipping_info | 11,086 | 0 | 4 |
| add_shipping_info to add_payment_info | 6,811 | 49 | 225 |
| add_payment_info to purchase | 4,845 | 111 | 526 |

## 6. Internal search
| used search | sessions | purchase sessions | purchase rate |
|---|---|---|---|
| no | 344,410 | 4,197 | 1.22% |
| yes | 15,719 | 651 | 4.14% |

3.4x higher conversion with search; 4.4% of sessions use search. Correlation only (intent and self-selection).

## 7. Data quality
- Timezone check: `event_date` equals the UTC date of `event_timestamp` (0 mismatches). Sao Paulo: 12.35%, New York: 20.79%, Los Angeles: 33.35% mismatch.
- No event without a session id; no same-timestamp collisions.
- Bug caught by the reconciliation test: a partitioned silver table in a sandbox project built with 0 rows while `unique` / `not_null` passed (decision 12).
- Output bug found by reading results: a rollup alias returned NULL instead of 'all' (decision 13).

## 8. Not analyzed yet
`fct_acquisition` (first-user source/medium), `fct_retention_weekly` and `fct_search_terms` are built and tested but their results are not summarized here.
