{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        schema='silver_cbs'
    )
}}
with source as (
    select * from {{ source('cbs', 'hist_transactional') }}
    
    {% if is_incremental() %}
        where tran_date > (select max(tran_date) from {{ this }})
    {% endif %}
)

SELECT 
    tran_id,
    foracid,
    tran_amount ,
    tran_date,
    tran_crncy,
    branch_id,
    tran_particular,           
    tran_remarks 
FROM source