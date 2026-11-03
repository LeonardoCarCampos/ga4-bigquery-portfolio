{#
  Gold: time between consecutive funnel steps inside a session (seconds), by device and overall.
  Only sessions that reached BOTH steps, in order, are measured (negative gaps are dropped).
#}

with gaps as (

    select
        coalesce(device_category, 'unknown')                                      as device_category,
        timestamp_diff(ts_add_to_cart, ts_view_item, second)                      as view_to_cart_s,
        timestamp_diff(ts_begin_checkout, ts_add_to_cart, second)                 as cart_to_checkout_s,
        timestamp_diff(ts_add_shipping_info, ts_begin_checkout, second)           as checkout_to_shipping_s,
        timestamp_diff(ts_add_payment_info, ts_add_shipping_info, second)         as shipping_to_payment_s,
        timestamp_diff(ts_purchase, ts_add_payment_info, second)                  as payment_to_purchase_s
    from {{ ref('int_ga4__sessions') }}

),

long_format as (

    select device_category as device, step, seconds
    from gaps
    unpivot (
        seconds for step in (
            view_to_cart_s,
            cart_to_checkout_s,
            checkout_to_shipping_s,
            shipping_to_payment_s,
            payment_to_purchase_s
        )
    )
    where seconds >= 0

)

select
    -- NOTE: grouped column is `device` (not `device_category`) on purpose. With an alias equal to the
    -- grouped column, BigQuery nulls the whole expression in the rollup row instead of returning 'all'.
    coalesce(device, 'all')                     as device_category,
    step,
    count(*)                                    as sessions,
    approx_quantiles(seconds, 100)[offset(25)]  as p25_seconds,
    approx_quantiles(seconds, 100)[offset(50)]  as median_seconds,
    approx_quantiles(seconds, 100)[offset(75)]  as p75_seconds,
    approx_quantiles(seconds, 100)[offset(90)]  as p90_seconds
from long_format
group by grouping sets ((device, step), (step))
