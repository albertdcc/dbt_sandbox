# Referência dbt_utils: 
# GET_QUERY_RESULTS_AS_DICT - https://github.com/dbt-labs/dbt-utils/tree/0.9.1/#get_query_results_as_dict-source
# PIVOT - https://github.com/dbt-labs/dbt-utils/tree/0.9.1/#pivot-source

{% set sql_statement %}
    select nome_vendedor, nome_produto, sum(vlr_total_venda) as vlr_total_venda from {{ ref('md_vendas') }}
    group by nome_vendedor, nome_produto
{% endset %}


select
  nome_vendedor,
  {{ dbt_utils.pivot(
      column='nome_produto',
      values=dbt_utils.get_column_values(ref('md_produtos'), 'nome_produto'),
      then_value='vlr_total_venda'
  ) }}
from (

{%- set results = dbt_utils.get_query_results_as_dict(sql_statement) -%}

  {% for i in range(0,(results['nome_vendedor']| length)) %}

    {# {{ log("Vendedor [" ~ loop.index ~ "]: " ~ results['nome_vendedor'][i], info = true) }} #}

    {% if not loop.first %}
      UNION ALL
    {% endif %}

    SELECT 
      '{{results['nome_vendedor'][i]}}' as nome_vendedor,
      '{{results['nome_produto'][i]}}' as nome_produto,
      '{{results['vlr_total_venda'][i]}}' as vlr_total_venda

  {% endfor %}

) as t
group by nome_vendedor