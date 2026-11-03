{#
  Gold: do sessions that use internal search convert more than sessions that do not?
  Grain: day x used_search. Compute rates after summing (see docs/decisoes.md).
#}

select
    session_date,
    search_events > 0                           as used_search,
    count(*)                                    as sessions,
    countif(ts_purchase is not null)            as purchase_sessions,
    sum(revenue_usd)                            as revenue_usd,
    sum(engagement_seconds)                     as engagement_seconds
from {{ ref('int_ga4__sessions') }}
group by session_date, used_search
