{#
  Gold: closed funnel for the whole period, one row per step, with conversion rates.
  Rates are computed AFTER summing session counts across days and devices.
#}

with steps as (

    select 1 as step_order, 'view_item'         as step, sum(closed_view_item)         as sessions from {{ ref('fct_funnel_daily') }}
    union all
    select 2, 'add_to_cart',       sum(closed_add_to_cart)       from {{ ref('fct_funnel_daily') }}
    union all
    select 3, 'begin_checkout',    sum(closed_begin_checkout)    from {{ ref('fct_funnel_daily') }}
    union all
    select 4, 'add_shipping_info', sum(closed_add_shipping_info) from {{ ref('fct_funnel_daily') }}
    union all
    select 5, 'add_payment_info',  sum(closed_add_payment_info)  from {{ ref('fct_funnel_daily') }}
    union all
    select 6, 'purchase',          sum(closed_purchase)          from {{ ref('fct_funnel_daily') }}

)

select
    step_order,
    step,
    sessions,
    safe_divide(sessions, lag(sessions) over (order by step_order))                  as pct_of_previous_step,
    safe_divide(sessions, first_value(sessions) over (order by step_order))          as pct_of_first_step
from steps
