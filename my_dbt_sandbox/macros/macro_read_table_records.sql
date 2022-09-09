{% macro macro_read_table_records() %}
    {% set query %}

        select matricula_vendedor
            , nome_vendedor
            , vlr_total_venda_sum
        from {{ref("dm_report_top3_vendedores")}}

    {% endset %}

    {% set results = run_query(query) %}
    {# execute is a Jinja variable that returns True when dbt is in "execute" mode i.e. True when running dbt run but False during dbt compile. #}

    {% if execute %}
        {% set results_list = results.rows %}

        {{ log("Results list length: " ~ results_list|length, info = true) }}

    {% else %}
        {% set results_list = [] %}
    {% endif %}

    {{ return(results_list) }}

{% endmacro %}