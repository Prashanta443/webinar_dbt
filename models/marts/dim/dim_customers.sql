{{ config(
    materialized='table',
    schema='gold',
    unique_key='cif_id'
) }}

with stg_customer as (
    select * from {{ ref('stg_customer') }}
)

select
    cif_id,
    name,
    address,
    phone_number,
    postal_code,
    country,
    email,
    father_name,
    mother_name,
    occupation,
    education,
    nationality,
    current_timestamp as dbt_created_at,
    current_timestamp as dbt_updated_at
from stg_customer
