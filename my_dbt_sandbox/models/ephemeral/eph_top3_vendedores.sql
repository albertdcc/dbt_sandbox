{{ 
    config(
        materialized='ephemeral'
    ) 
}}

select mdv.matricula_vendedor
    , mdv.nome_vendedor
    , sum(mdv.vlr_total_venda) as vlr_total_venda_sum
from {{ref("md_vendas")}} mdv
group by mdv.matricula_vendedor, mdv.nome_vendedor
order by vlr_total_venda_sum desc
limit 3
