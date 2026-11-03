{#
  Gold: weekly retention by cohort.
  Cohort = week of the user's first observed session in the dataset window.
  CAVEAT: the window starts on 2020-11-01, so week-0 cohorts also contain returning users
  (left-censoring). Treat the first cohort as "already existing users".
#}

with user_weeks as (

    select
        user_pseudo_id,
        date_trunc(session_date, week(monday)) as session_week
    from {{ ref('int_ga4__sessions') }}
    group by user_pseudo_id, session_week

),

cohorts as (

    select
        user_pseudo_id,
        min(session_week) as cohort_week
    from user_weeks
    group by user_pseudo_id

),

activity as (

    select
        c.cohort_week,
        date_diff(u.session_week, c.cohort_week, week)  as weeks_since_first,
        count(distinct u.user_pseudo_id)                as active_users
    from user_weeks as u
    inner join cohorts as c using (user_pseudo_id)
    group by c.cohort_week, weeks_since_first

)

select
    cohort_week,
    weeks_since_first,
    active_users,
    first_value(active_users) over (partition by cohort_week order by weeks_since_first) as cohort_size,
    safe_divide(
        active_users,
        first_value(active_users) over (partition by cohort_week order by weeks_since_first)
    )                                                                                    as retention_rate
from activity
