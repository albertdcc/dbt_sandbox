{{ 
    config(
        materialized='table'
    ) 
}}

select matricula_vendedor
    , nome_vendedor
    , vlr_total_venda_sum
from {{ref("eph_top3_vendedores")}}
