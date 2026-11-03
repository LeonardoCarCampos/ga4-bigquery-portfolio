-- Fails if the data-quality scorecard does not add up to the staging row count.
with dq as (
    select sum(events) as n from {{ ref('dq_events_daily') }}
),

stg as (
    select count(*) as n from {{ ref('stg_ga4__events') }}
)

select
    dq.n  as dq_events,
    stg.n as staging_events
from dq
cross join stg
where dq.n != stg.n
