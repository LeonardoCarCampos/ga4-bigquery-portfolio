-- Fails (returns a row) if staging lost or multiplied events versus the raw source.
with src as (
    select count(*) as n
    from {{ source('ga4_ecommerce', 'events') }}
    where _table_suffix between '{{ var("start_date") }}' and '{{ var("end_date") }}'
),

stg as (
    select count(*) as n
    from {{ ref('stg_ga4__events') }}
)

select
    src.n as source_events,
    stg.n as staging_events
from src
cross join stg
where src.n != stg.n
