{#
  Gold: internal search terms, how often they are searched and how many of those sessions purchase.
  Terms are lower-cased and trimmed. Requires the event param `search_term` on view_search_results
  (confirm with sql/exploration/08_search_event_params.sql).
#}

with terms as (

    select
        session_key,
        lower(trim(search_term))    as search_term,
        count(*)                    as searches
    from {{ ref('stg_ga4__events') }}
    where event_name = 'view_search_results'
      and search_term is not null
      and session_key is not null
    group by session_key, search_term

)

select
    t.search_term,
    sum(t.searches)                                         as searches,
    count(*)                                                as sessions,
    countif(s.ts_purchase is not null)                      as purchase_sessions,
    safe_divide(countif(s.ts_purchase is not null), count(*)) as purchase_rate
from terms as t
inner join {{ ref('int_ga4__sessions') }} as s using (session_key)
group by t.search_term
