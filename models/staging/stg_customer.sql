{{ config(
    materialized='table',
    schema='silver_cbs'
) }}

with source as (
    select * from {{ source('cbs', 'customer') }}
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
    nationality
from source