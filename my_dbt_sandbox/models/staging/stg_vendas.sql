{{ 
    config(
        materialized='incremental',
        unique_key='id'
    ) 
}}

# Na camada STAGING recomenda-se que se faça apenas tratamentos básicos, com TRIM, IFNULL, etc.

with source_data as (

    select v.id
        , v.data_venda
        , v.id_cliente
        , v.matricula_vendedor
        , v.codigo_produto
        , v.qtde
        , v.valor_total
    from {{ source("origem_db", "vendas") }} v
    
    {% if is_incremental() %} -- Filtro só é aplicado nas execuções incrementais
    -- `this` é uma implementação do dbt para buscar a tabela target, ou seja, a que é carregada por esta consulta
    WHERE v.data_venda >= (select max(v_stg.data_venda) from {{ this }} v_stg)
    {% endif %}

)

select *
from source_data