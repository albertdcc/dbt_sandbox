{{ config(materialized='view') }}

# Na camada STAGING recomenda-se que se faça apenas tratamentos básicos, com TRIM, IFNULL, etc.

with source_data as (

    select matricula
        , trim(nome) as nome
    from {{ source("origem_db", "vendedores") }}
    
)

select *
from source_data