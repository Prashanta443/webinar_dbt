{{ config(
    materialized='table',
    schema='silver_cbs'
) }}

with source as (
    select * from {{ source('cbs', 'account') }}
)
SELECT 
    foracid,
    cif_id,
    branch_id ,
    clr_bal_amt ,
    lien_amt ,
    acct_cls_flg,
    product_id  ,
    schm_type,
    schm_code ,
    acct_crncy_code  
FROM source