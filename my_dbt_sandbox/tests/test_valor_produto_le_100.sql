{{config(severity="warn")}}

# Testa se existe algum produto com valor menor ou igua a 100.00

select codigo_produto, valor_unitario_produto, CURRENT_TIMESTAMP
from {{ref('md_produtos')}} 
where valor_unitario_produto <= {{ var("valor_minimo_produto") }}