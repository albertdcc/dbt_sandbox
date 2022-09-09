{{ 
    config(
        materialized='incremental', 
        unique_key='id'
    ) 
}}

# 

select ve.id
    , ve.data_venda as data_venda
    , cl.nome as nome_cliente
    , vr.nome as nome_vendedor
    , vr.matricula as matricula_vendedor
    , pd.codigo as codigo_produto
    , pd.nome as nome_produto
    , pd.valor as valor_unitario_produto
    , ve.qtde as qtd_vendida
    , ve.valor_total as vlr_total_venda
    , current_timestamp AS data_inclusao_registro
    , current_timestamp AS data_alteracao_registro
from {{ ref("stg_vendas") }} ve
left join {{ ref("stg_clientes") }} cl on (cl.id = ve.id_cliente)
left join {{ ref("stg_vendedores") }} vr on (vr.matricula = ve.matricula_vendedor)
left join {{ ref("stg_produtos") }} pd on (pd.codigo = ve.codigo_produto)

{% if is_incremental() %} -- Filtro só é aplicado nas execuções incrementais
-- `this` é uma implementação do dbt para buscar a tabela target, ou seja, a que é carregada por esta consulta
WHERE ve.data_venda >= (select max(v_md.data_venda) from {{ this }} v_md)
{% endif %}

