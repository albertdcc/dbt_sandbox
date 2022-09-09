{% test sql_injection_prevention(model, column_name) %}

WITH grouped_expression AS (
    # Busca se o conteúdo da coluna contém algum dos padrões procurados.
    # Se encontrar, `regexp_instr` retornará o índice e a comparação com 0 será FALSE, logo, `expression` será FALSE
    SELECT
        regexp_instr({{ column_name }}, '[`;.*+%$#@!?|]', 1, 1) = 0
        AND regexp_instr({{ column_name }}, '[aA][lL][tT][eE][rR]', 1, 1) = 0
        AND regexp_instr({{ column_name }}, '[cC][rR][eE][aA][tT][eE]', 1, 1) = 0
        AND regexp_instr({{ column_name }}, '[dD][eE][lL][eE][tT][eE]', 1, 1) = 0
        AND regexp_instr({{ column_name }}, '[dD][rR][oO][pP]', 1, 1) = 0
        AND regexp_instr({{ column_name }}, '[eE][xX][eE][cC][uU][tT][eE]', 1, 1) = 0
        AND regexp_instr({{ column_name }}, '[iI][nN][sS][eE][rR][tT]', 1, 1) = 0
        AND regexp_instr({{ column_name }}, '[mM][eE][rR][gG][eE]', 1, 1) = 0
        AND regexp_instr({{ column_name }}, '[iI][nN][sS][eE][rR][tT]', 1, 1) = 0
        AND regexp_instr({{ column_name }}, '[uU][pP][dD][aA][tT][eE]', 1, 1) = 0
        AND regexp_instr({{ column_name }}, '[uU][nN][iI][oO][nN]', 1, 1) = 0
        AS expression
    FROM {{ model }}
),
validation_errors AS (
    SELECT * FROM grouped_expression WHERE expression = FALSE
)
SELECT * FROM validation_errors

{% endtest %}
