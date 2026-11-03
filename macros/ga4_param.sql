{#
  Extracts one value from the GA4 `event_params` array as a scalar column.

  Usage:  {{ ga4_param('page_location', 'string') }} as page_location
          {{ ga4_param('ga_session_id', 'int') }}    as ga_session_id

  value_type: string | int | double | float

  Why a scalar subquery instead of `FROM t, UNNEST(event_params)`?
  A comma-UNNEST is an implicit CROSS JOIN: it multiplies rows (one per param)
  and drops events whose array is empty. The scalar subquery keeps exactly one
  row per event and returns NULL when the key is absent.

  `limit 1` keeps the model from failing if a key ever repeats inside one event;
  sql/exploration/05_repeated_keys_per_event.sql measures whether that happens.
#}
{% macro ga4_param(key, value_type='string') %}
    (
        select ep.value.{{ value_type }}_value
        from unnest(event_params) as ep
        where ep.key = '{{ key }}'
        limit 1
    )
{% endmacro %}
