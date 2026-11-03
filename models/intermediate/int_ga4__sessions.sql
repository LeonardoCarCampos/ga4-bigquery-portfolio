{{
    config(
        materialized='table',
        cluster_by=['session_key']
    )
}}

{#
  Our own sessionization: one row per (user_pseudo_id, ga_session_id).
  Funnel timestamps hold the FIRST time each step happened in the session, which lets the
  gold layer build funnels and time-between-steps without self-joins.
#}

select
    session_key,
    any_value(user_pseudo_id)                                       as user_pseudo_id,
    any_value(ga_session_id)                                        as ga_session_id,
    max(ga_session_number)                                          as ga_session_number,
    date(min(event_ts), '{{ var("timezone") }}')                    as session_date,
    min(event_ts)                                                   as session_start_ts,
    max(event_ts)                                                   as session_end_ts,
    timestamp_diff(max(event_ts), min(event_ts), second)            as session_span_seconds,
    count(*)                                                        as events,
    countif(event_name = 'page_view')                               as page_views,
    sum(coalesce(engagement_time_msec, 0)) / 1000.0                 as engagement_seconds,
    logical_or(event_name = 'session_start')                        as has_session_start_event,

    array_agg(device_category ignore nulls order by event_ts limit 1)[safe_offset(0)]     as device_category,
    array_agg(country ignore nulls order by event_ts limit 1)[safe_offset(0)]             as country,
    array_agg(first_user_source ignore nulls order by event_ts limit 1)[safe_offset(0)]   as first_user_source,
    array_agg(first_user_medium ignore nulls order by event_ts limit 1)[safe_offset(0)]   as first_user_medium,

    min(if(event_name = 'view_item',          event_ts, null))      as ts_view_item,
    min(if(event_name = 'add_to_cart',        event_ts, null))      as ts_add_to_cart,
    min(if(event_name = 'begin_checkout',     event_ts, null))      as ts_begin_checkout,
    min(if(event_name = 'add_shipping_info',  event_ts, null))      as ts_add_shipping_info,
    min(if(event_name = 'add_payment_info',   event_ts, null))      as ts_add_payment_info,
    min(if(event_name = 'purchase',           event_ts, null))      as ts_purchase,

    countif(event_name = 'view_search_results')                     as search_events,
    countif(event_name = 'purchase')                                as purchase_events,
    sum(if(event_name = 'purchase', coalesce(purchase_revenue_usd, 0), 0)) as revenue_usd

from {{ ref('stg_ga4__events') }}
where session_key is not null
group by session_key
