{{
    config(
        materialized='table',
        cluster_by=['event_name', 'user_pseudo_id']
    )
}}

{#
  Silver layer: one row per GA4 event, flat columns, no row multiplication.

  - event_params values are extracted with scalar subqueries (macro ga4_param).
  - GA4 exports have no event_id, so we build event_key = md5(user, timestamp, name, dup_seq),
    where dup_seq numbers events that share (user, timestamp, name). This keeps the key unique
    even when two events collide on the natural key.
  - event_date is the date from the export (equal to the UTC date in this dataset); event_date_local is derived from the
    UTC event_timestamp in var('timezone'). Comparing them is a data-quality check (dq_events_daily).
#}

with source as (

    select
        event_date as event_date_raw,
        event_timestamp,
        event_name,
        user_pseudo_id,
        platform,
        device.category                       as device_category,
        device.operating_system               as operating_system,
        geo.country                           as country,
        traffic_source.source                 as first_user_source,
        traffic_source.medium                 as first_user_medium,
        traffic_source.name                   as first_user_campaign,
        ecommerce.transaction_id              as transaction_id,
        ecommerce.purchase_revenue_in_usd     as purchase_revenue_usd,
        event_params
    from {{ source('ga4_ecommerce', 'events') }}
    where _table_suffix between '{{ var("start_date") }}' and '{{ var("end_date") }}'

),

parsed as (

    select
        parse_date('%Y%m%d', event_date_raw)                    as event_date,
        timestamp_micros(event_timestamp)                       as event_ts,
        event_timestamp,
        event_name,
        user_pseudo_id,
        platform,
        device_category,
        operating_system,
        country,
        first_user_source,
        first_user_medium,
        first_user_campaign,
        transaction_id,
        purchase_revenue_usd,
        {{ ga4_param('ga_session_id', 'int') }}                 as ga_session_id,
        {{ ga4_param('ga_session_number', 'int') }}             as ga_session_number,
        {{ ga4_param('page_location', 'string') }}              as page_location,
        {{ ga4_param('page_title', 'string') }}                 as page_title,
        {{ ga4_param('page_referrer', 'string') }}              as page_referrer,
        {{ ga4_param('search_term', 'string') }}                as search_term,
        {{ ga4_param('engagement_time_msec', 'int') }}          as engagement_time_msec,
        event_params
    from source

),

numbered as (

    select
        *,
        row_number() over (
            partition by user_pseudo_id, event_timestamp, event_name
            order by to_json_string(event_params)
        ) as dup_seq
    from parsed

)

select
    to_hex(md5(concat(
        coalesce(user_pseudo_id, ''), '|',
        cast(event_timestamp as string), '|',
        event_name, '|',
        cast(dup_seq as string)
    )))                                                         as event_key,
    if(
        ga_session_id is null,
        null,
        concat(user_pseudo_id, '-', cast(ga_session_id as string))
    )                                                           as session_key,
    event_date,
    date(event_ts, '{{ var("timezone") }}')                     as event_date_local,
    event_ts,
    event_name,
    user_pseudo_id,
    ga_session_id,
    ga_session_number,
    platform,
    device_category,
    operating_system,
    country,
    first_user_source,
    first_user_medium,
    first_user_campaign,
    page_location,
    page_title,
    page_referrer,
    search_term,
    engagement_time_msec,
    transaction_id,
    purchase_revenue_usd,
    dup_seq
from numbered
