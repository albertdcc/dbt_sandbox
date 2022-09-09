{% snapshot md_produtos_snapshot %}

# invalidate_hard_deletes = True, --> Me parece incompatível com MySQL pois gera um MERGE que não existe neste banco

{{
    config(
      unique_key='codigo_produto',
      strategy='check',
      check_cols=['valor_unitario_produto'],
    )
}}

select * from {{ ref('md_produtos') }}

{% endsnapshot %}