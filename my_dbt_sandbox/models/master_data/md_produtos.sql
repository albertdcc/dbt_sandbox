{{ 
    config(
        materialized='table', 
        unique_key='codigo_produto'
    ) 
}}

# Teste se a tabela existe
# Returns a cached Relation object or None if the relation does not exist:
{%- set ref_relation = adapter.get_relation(
      database=ref("produtos_desconto").database,
      schema=ref("produtos_desconto").schema,
      identifier=ref("produtos_desconto").name
    ) 
-%}

{% set table_exists=ref_relation is not none %}

# Se a tabela de Seeds de desconto de produto existe, faz uma consulta diferenciada, considerando os cálculos de desconto
{% if table_exists %}

    select pd.codigo as codigo_produto
        , pd.nome as nome_produto
        , CASE WHEN pdd.id_produto IS null THEN pd.valor ELSE (1.0 - pdd.desconto) * pd.valor END as valor_unitario_produto
        , current_timestamp AS data_inclusao_registro
        , current_timestamp AS data_alteracao_registro
    from {{ ref("stg_produtos") }} pd
    left join {{ref("produtos_desconto")}} pdd on (pdd.id_produto = pd.codigo)

{% else %}

    select pd.codigo as codigo_produto
        , pd.nome as nome_produto
        , pd.valor as valor_unitario_produto
        , current_timestamp AS data_inclusao_registro
        , current_timestamp AS data_alteracao_registro
    from {{ ref("stg_produtos") }} pd

{% endif %}


