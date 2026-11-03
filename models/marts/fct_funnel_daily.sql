{#
  Gold: daily purchase funnel by device, counted in SESSIONS (not events).

  open_*   : sessions that fired the event, regardless of earlier steps.
  closed_* : a step only counts if every earlier step also happened in the session.
  Rates are intentionally NOT stored here: ratios must be computed after summing counts
  (see fct_funnel_overall), never averaged across days.
#}

select
    session_date,
    coalesce(device_category, 'unknown')                                  as device_category,
    count(*)                                                              as sessions,

    countif(ts_view_item is not null)                                     as open_view_item,
    countif(ts_add_to_cart is not null)                                   as open_add_to_cart,
    countif(ts_begin_checkout is not null)                                as open_begin_checkout,
    countif(ts_add_shipping_info is not null)                             as open_add_shipping_info,
    countif(ts_add_payment_info is not null)                              as open_add_payment_info,
    countif(ts_purchase is not null)                                      as open_purchase,

    countif(ts_view_item is not null)                                     as closed_view_item,
    countif(ts_view_item is not null
        and ts_add_to_cart is not null)                                   as closed_add_to_cart,
    countif(ts_view_item is not null
        and ts_add_to_cart is not null
        and ts_begin_checkout is not null)                                as closed_begin_checkout,
    countif(ts_view_item is not null
        and ts_add_to_cart is not null
        and ts_begin_checkout is not null
        and ts_add_shipping_info is not null)                             as closed_add_shipping_info,
    countif(ts_view_item is not null
        and ts_add_to_cart is not null
        and ts_begin_checkout is not null
        and ts_add_shipping_info is not null
        and ts_add_payment_info is not null)                              as closed_add_payment_info,
    countif(ts_view_item is not null
        and ts_add_to_cart is not null
        and ts_begin_checkout is not null
        and ts_add_shipping_info is not null
        and ts_add_payment_info is not null
        and ts_purchase is not null)                                      as closed_purchase,

    -- tagging integrity: steps that happened without the step before them
    countif(ts_add_to_cart is not null and ts_view_item is null)          as cart_without_view_item,
    countif(ts_purchase is not null and ts_begin_checkout is null)        as purchase_without_checkout,
    countif(ts_add_payment_info is not null
        and ts_add_shipping_info is null)                                 as payment_without_shipping

from {{ ref('int_ga4__sessions') }}
group by session_date, device_category
