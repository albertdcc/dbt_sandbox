{{ config(materialized='view') }}

# Na camada STAGING recomenda-se que se faça apenas tratamentos básicos, com TRIM, IFNULL, etc.

with source_data as (

    select codigo
        , trim(nome) as nome
        , valor
    from {{ source("origem_db", "produtos") }}
    
)

select *
from source_data