{{ 
    config(
        materialized='ephemeral'
    ) 
}}

-- Jinja reference: https://jinja.palletsprojects.com/en/3.0.x/templates/

{% for record in macro_read_table_records() %}

        {% if not loop.first %}
            UNION ALL
        {% endif %}
            SELECT '{{record.nome_vendedor}}' as nome_vendedor

    {{ log("Vendedor [" ~ loop.index ~ "]: " ~ record.nome_vendedor, info = true) }}

{% endfor %}