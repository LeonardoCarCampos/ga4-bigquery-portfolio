-- Fails if the daily funnel does not account for every session in int_ga4__sessions.
with funnel as (
    select sum(sessions) as n from {{ ref('fct_funnel_daily') }}
),

sessions as (
    select count(*) as n from {{ ref('int_ga4__sessions') }}
)

select
    funnel.n   as funnel_sessions,
    sessions.n as total_sessions
from funnel
cross join sessions
where funnel.n != sessions.n
