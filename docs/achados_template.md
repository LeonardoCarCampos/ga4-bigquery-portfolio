# Findings (fill in with YOUR numbers, then copy the highlights to README.md)

Run date: ____    Period: 2020-11-01 to 2021-01-31    Timezone used: ____

## 1. Dataset sanity
- Total events: ____ (reconciled: flat count == raw count? yes/no)
- Distinct event names: ____
- Universal event_params keys: ____
- Keys that repeat inside one event: ____ (none expected)

## 2. The UNNEST(items) pitfall
| event_name | correct_events | inflated_rows | inflation_ratio |
|---|---|---|---|
| | | | |

Takeaway (one sentence): ____

## 3. Funnel (closed, sessions)
| step | sessions | % of previous | % of first |
|---|---|---|---|
| view_item | | | |
| add_to_cart | | | |
| begin_checkout | | | |
| add_shipping_info | | | |
| add_payment_info | | | |
| purchase | | | |

Biggest drop: ____    Mobile vs desktop difference: ____
Integrity counters (from fct_funnel_daily): purchase_without_checkout = ____, cart_without_view_item = ____

## 4. Time between steps (median / p90, seconds)
| step | median | p90 |
|---|---|---|
| | | |

## 5. Internal search
- Sessions with search: ____ of ____ (___%)
- Purchase rate with search: ____ vs without: ____
- Top 5 terms: ____
- Searches without term: ____
- Caveat: sessions that search are different from sessions that do not (self-selection); this is correlation.

## 6. Acquisition and retention
- Best converting first-user source/medium (min. sessions threshold): ____
- Week-1 retention of the cohorts after the first: ____

## 7. Data quality
- Timezone that matches event_date: ____ (mismatch with UTC: ___%)
- Events without session id: ____ (concentrated in: ____)
- Same-timestamp collisions: ____
- Failed dbt tests and what they revealed: ____

## 8. Lessons learned
____
