{#
  Gold: sessions and conversion by first-user source/medium and device, per month.
  CAVEAT: GA4 export `traffic_source` is the user's first acquisition source, not the session's source.
#}

select
    date_trunc(session_date, month)                         as session_month,
    coalesce(first_user_source, '(unknown)')                as first_user_source,
    coalesce(first_user_medium, '(unknown)')                as first_user_medium,
    coalesce(device_category, 'unknown')                    as device_category,
    count(*)                                                as sessions,
    count(distinct user_pseudo_id)                          as users,
    countif(ts_purchase is not null)                        as purchase_sessions,
    safe_divide(countif(ts_purchase is not null), count(*)) as conversion_rate,
    sum(revenue_usd)                                        as revenue_usd
from {{ ref('int_ga4__sessions') }}
group by session_month, first_user_source, first_user_medium, device_category
