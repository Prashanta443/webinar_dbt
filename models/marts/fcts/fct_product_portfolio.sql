-- ============================================================
-- models/marts/fcts/product_portfolio.sql
-- Purpose  : Product portfolio summary — customer count and
--            balance aggregated by schm_type and schm_code
-- Source   : stg_account + stg_customer
-- Strategy : Full table refresh
-- ============================================================

{{ config(
    materialized = 'table',
    schema       = 'gold',
    tags         = ['gold', 'product', 'portfolio']
) }}

with account as (
    select * from {{ ref('stg_account') }}
),

customer as (
    select cif_id from {{ ref('stg_customer') }}
),

-- ── enrich each account row with product labels ───────────────────────────────
account_enriched as (
    select
        a.foracid,
        a.cif_id,
        a.clr_bal_amt,
        a.lien_amt,
        a.acct_cls_flg,
        a.schm_type,
        a.schm_code,
        a.acct_crncy_code,

        -- high-level product category
        case a.schm_type
            when 'SA' then 'Deposit'
            when 'CA' then 'Deposit'
            when 'FD' then 'Deposit'
            when 'RD' then 'Deposit'
            when 'LD' then 'Loan'
        end as product_category,

        -- human-readable scheme type label
        case a.schm_type
            when 'SA' then 'Savings Account'
            when 'CA' then 'Current Account'
            when 'FD' then 'Fixed Deposit'
            when 'RD' then 'Recurring Deposit'
            when 'LD' then 'Loan Account'
        end as product_type_label,

        -- human-readable scheme code (product name)
        case a.schm_code
            when 'SAV001' then 'Regular Savings Account'
            when 'SAV002' then 'Premium Savings Account'
            when 'SAV003' then 'Junior Savings Account'
            when 'CUR001' then 'Individual Current Account'
            when 'CUR002' then 'Business Current Account'
            when 'FXD001' then 'Fixed Deposit 3 Months'
            when 'FXD002' then 'Fixed Deposit 6 Months'
            when 'FXD003' then 'Fixed Deposit 12 Months'
            when 'FXD004' then 'Fixed Deposit 24 Months'
            when 'REC001' then 'Recurring Deposit Monthly'
            when 'REC002' then 'Recurring Deposit Quarterly'
            when 'LON001' then 'Personal Loan Account'
            when 'LON002' then 'Home Loan Account'
            when 'LON003' then 'Business Loan Account'
            when 'LON004' then 'Hire Purchase Loan'
        end as product_desc

    from account a
    inner join customer c on a.cif_id = c.cif_id
),

-- ── aggregate to one row per schm_type + schm_code ────────────────────────────
portfolio_summary as (
    select
        product_category,
        product_type_label,

        -- customer counts
        count(distinct cif_id)                                          as total_customers,
        count(distinct case when acct_cls_flg = 'N' then cif_id end)   as active_customers,
        count(distinct case when acct_cls_flg = 'Y' then cif_id end)   as churned_customers,

        -- account counts
        count(foracid)                                                  as total_accounts,
        count(case when acct_cls_flg = 'N' then foracid end)           as active_accounts,
        count(case when acct_cls_flg = 'Y' then foracid end)           as closed_accounts,

        -- balance aggregates (active accounts only)
        round(sum(case when acct_cls_flg = 'N' then clr_bal_amt else 0 end), 2) as total_balance,
        round(avg(case when acct_cls_flg = 'N' then clr_bal_amt end),  2)       as avg_balance_per_account

    from account_enriched
    group by
        product_category,
        product_type_label
        )

select
    product_category,
    product_type_label,
    total_customers,
    active_customers,
    churned_customers,
    total_accounts,
    active_accounts,
    closed_accounts,
    total_balance,
    avg_balance_per_account,
    current_timestamp as dbt_updated_at
from portfolio_summary
order by product_category, product_type_label