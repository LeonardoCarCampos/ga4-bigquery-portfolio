{#
  Gold: data-quality scorecard, one row per day x event_name.
  Feeds the "why do two numbers for the same event diverge?" part of the story.
#}

select
    event_date,
    event_name,
    count(*)                                                                         as events,
    countif(session_key is null)                                                     as events_without_session,
    countif(page_location is null)                                                   as events_without_page_location,
    countif(dup_seq > 1)                                                             as same_timestamp_collisions,
    countif(event_date != event_date_local)                                          as event_date_differs_from_local_date,
    countif(event_name = 'purchase' and transaction_id is null)                      as purchases_without_transaction_id,
    count(distinct if(event_name = 'purchase', transaction_id, null))                as distinct_transactions,
    countif(event_name = 'view_search_results' and search_term is null)              as searches_without_term
from {{ ref('stg_ga4__events') }}
group by event_date, event_name
