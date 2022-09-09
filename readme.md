# DBT Sandbox - Projeto pessoal para estudo e prática com a ferramenta

setembro/2022

Projeto pessoal criado para explorar funcionalidades do DBT e documentar comandos úteis e boas práticas.

Não é pretensão deste projeto fazer um modelo de dados com as melhores práticas de modelagem e normalização. A intenção é explorar as funcionalidades do DBT e um caso de uso da mesma, ainda que para fins simplesmente didáticos e sem real utilidade.

---

## Pré-requisitos

- WSL2 com Ubuntu 20.04
- Docker Engine instalada e funcionando no WSL2

- Criar `venv`: `python3 -m venv venv`
- Ativar `venv`: `source ./venv/bin/activate`

- Comandos necessários para instalação em ambiente local:
    - `sudo apt-get update`
    - `sudo apt-get upgrade`
    - `sudo apt install libmysqlclient-dev`
    - Somente assim pude rodar a instalação `pip install mysqlclient==2.1.1` dentro do venv apropriado.

- Instalar pacotes: `python -m pip install --no-cache-dir -r requirements.txt`

---

## Configuração DBT

- Após a instalação dos `requirements`, dbt estará disponível. Pode ser verificado rodando o seguinte comando com o `venv` ativado: `dbt --version`

- Iniciar um projeto no diretório atual: `dbt init my_dbt_sandbox`

- Fazer as devidas configurações no arquivo `/home/adc/.dbt/profiles.yml`. Para este projeto foi usado o `Community Plugin` para MySQL: https://docs.getdbt.com/reference/warehouse-profiles/mysql-profile

- Executar o container do banco: `docker-compose up`
    - Vai executar o servidor MySQL e também o Adminer para auxiliar no gerenciamento do MySQL

- Entrar no diretório do projeto `cd my_dbt_sandbox` e testar conexão: `dbt debug`

- Incluir os packages de extensão do DBT no arquivo `packages.yml` e instalar com o comando `dbt deps`
    - Exemplo: `dbt-labs/dbt_utils` e `calogica/dbt_date` (não compatível com `mysql community adapter` até onde pude checar) 

- Executar o script para instaciar o banco de dados e as tabelas que serão usadas neste projeto: `python ../0_init_db.py`
    - Será criado o banco `dbt_sandbox_origem_db`

- Executar o dbt: `dbt run`

- Para rodar apenas um modelo (ou qualquer recurso): `dbt run --select stg_vendas`

- Logs
  - O arquivo `dbt.log` mostra logs de tudo o que o DBT executa
  - Uma vez que o log de queries foi ativado na criação do database MySQL, esta consulta deve ser útil para verificar o que está sendo de fato executado no banco (server `db`, database `mysql`, tabela `general_log` - a interface do Adminer possibita navegação simples pelos dados): 
    - Foi com o debug abaixo que pude encontrar, por exemplo, o DELETE e o INSERT gerados quando usa-se a clásula `unique_key='id'` na `stg_vendas` com carga incremental, como consta também no arquivo de log `dbt.log`
```sql
SELECT * FROM `general_log` WHERE `argument` NOT LIKE 'SHOW %' ORDER BY `event_time` DESC LIMIT 50
```

---

## Tutorial DBT

Link oficial: https://docs.getdbt.com/guides/getting-started/learning-more/getting-started-dbt-core

Commnand reference: https://docs.getdbt.com/reference/dbt-commands

Features docs: https://docs.getdbt.com/docs/building-a-dbt-project/projects

---

## Executando o DBT

### Testando o funcionamento básico

**EXECUÇÃO**

- Executar o script para instanciar o banco de dados e as tabelas que serão usadas neste projeto: `python ../0_init_db.py`
    - Será criado o banco `dbt_sandbox_origem_db`

- Executar o dbt: `dbt run` ou `dbt run --select stg_vendas md_vendas`

Obs.: Para fazer uma nova execução limpa, basta fazer o DROP de todos os bancos de dados criados por este projeto (com prefixo `dbt_sandbox`)

**RESULTADO**

De acordo com os modelos criados, devem ter sido criados dois novos databases: um para tabelas STAGING e outro para o MASTER_DATA

---

### Testando a carga incremental da `stg_vendas` e `md_vendas`

Documentação dos Modelos Incrementais: https://docs.getdbt.com/docs/building-a-dbt-project/building-models/configuring-incremental-models

**EXECUÇÃO**

- Executar o script para gerar novas vendas mais recentes: `python ../1_incremental_vendas.py`

- Executar novamente `dbt run`
  - Se for alterado alguma estrutura das tabelas com carga incremental, usar `dbt run --full-refresh`

**RESULTADO**

As novas vendas criadas devem ter sido carregadas na tabela `md_vendas`

- NOTAS
    - O DBT, quando executa materalizações como `table`, faz um DROP e depois CREATE do objeto target. Isso não é compatível com o Bigquery, por exemplo, pois, ao fazer drop de um objeto, as permissões associadas a ele são perdidas, mesmo se recriado com o mesmo nome. Uma forma de contornar isso no DBT é fazer a materialização como `incremental` e usar um `pre-hook` para truncar a tabela target `this`, alcançando assim o efeito de carga full da tabela target sem fazer seu DROP.
    - Ao usar a cláusula `unique_key` na carga incremental, o DBT vai gerar um MERGE ou DELETE+INSERT (se o banco em questão não suportar MERGE) com o intuito de evitar chaves duplicadas. Se não for possível usar o `unique_key`, uma alternativa é usar um `pre-hook` para um DELETE dos registros que devem ser atualizados.
    - A cláusula `post-hook` também pode ser usada, por exemplo, para dar permissão (grant) a usuários nos objetos criados/recriados pelo DBT.

---

### Ephemeral

O uso da materialização `ephemeral` é equivalente a uma CTE (cláusula WITH).

**EXECUÇÃO**

- Executar o DBT: `dbt run --select eph_top3_vendedores md_report_top3_vendedores`

**RESULTADO**

Deve ter sido criada uma nova tabela no banco de Master Data contendo o resultado do modelo ephemeral (os top 3 vendedores)

---

### DBT Macro

**EXECUÇÃO**

- Executar o DBT: `dbt run --select eph_call_macro`

**RESULTADO**

O comando acima executa um modelo ephemeral que chama uma MACRO que lê todos os registros de uma tabela. O modelo formata um SELECT UNION ALL e também imprime log desses registros na saída da linha de comando.

- NOTAS:
    - O comando `dbt run-operation` é usado para chamar macros. Pode ajudar no desenvolvimento. Exemplo: `dbt run-operation macro_read_table_records`

---

### DBT Seeds

Os arquivos CSV na pasta `seeds` serão automaticamente importados em objetos no banco.

Os seeds podem ser configurados e documentados no arquivo `dbt_project.yml` ou em arquivos de configuração próprios.

Propriedades para documentação: https://docs.getdbt.com/reference/seed-properties

Configuração: https://docs.getdbt.com/reference/seed-configs

- NOTAS
    - A recomendação é configurar o tipo das colunas (`column_types`) somente se a inferência automática não estiver funcionando bem.

**EXECUÇÃO**

- Executar o DBT: `dbt seed` ou `dbt seed --full-refresh` em caso de alteração na estrutura 

**RESULTADO**

Nova tabela criada em novo banco de dados `dbt_sandbox_dbt_seeds` com o conteúdo do arquivo CSV.

Ao executar o comando `dbt run`, o modelo `md_produtos` já está preparado para identificar se existe uma tabela de descontos e, em caso positivo, aplicar estes descontos nos preços dos produtos.

---

### DBT SNAPSHOT

Referência: https://docs.getdbt.com/docs/building-a-dbt-project/snapshots

Link interessante: https://hightouch.com/blog/dbt-snapshots-guide/

Neste exemplo, está sendo usada a estratégia de `check` que compara valor das colunas informadas mas existe também a estratégia de `timestamp` que rastreia os registros atualizados e novos através de uma coluna de timestamp.

Também há a cláusula `invalidate_hard_deletes` que rastreia e invalida os registros que foram excluídos na origem.

- NOTAS
    - Acredito que a cláusula `invalidate_hard_deletes` não funcione no MySQL pois, pelo que vi no código-fonte do DBT, para implementar essa lógica, é usado o MERGE que é incompatível com MySQL.

**EXECUÇÃO**

Executar o DBT: 

1. `dbt snapshot` para criar a primeira "versão" da tabela de snapshot

2. `dbt seed` ou `dbt seed --full-refresh` para carregar os descontos

3. `dbt run` para aplicar os descontos na `md_produtos`

4. `dbt snapshot` para gerar nova versão invalidando registros alterados e incluindo suas novas versões válidas

**RESULTADO**

Na tabela de snapshots devem constar as versões invalidadas dos produtos (com preço antes do desconto) e as versões válidas dos produtos (com preços após o desconto)

---

### Usando dbt.utils

O `dbt_utils` é um pacote com muitas funcionalidades úteis. Para exemplificar um uso:

**EXECUÇÃO**

Executar o DBT: `dbt run --select dm_report_valor_vendas_por_vendedor_e_produto`

**RESULTADO**

O modelo `dm_report_valor_vendas_por_vendedor_e_produto` faz uso da macro `dbt_utils.get_query_results_as_dict` e de algumas ferramentas da linguagem Jinja para iterar pelo resultado em formato de dicionário. Também faz uso da macro `dbt_utils.pivot` para formatar uma tabela (matriz) mostrando o valor total de vendas por vendedor e produto.

Ao final da execução, deve ter sido criada nova tabela com o resultado da consulta executada e "pivotada" pelas macros. 

---

### DBT Source Freshness

Referência: https://docs.getdbt.com/reference/resource-properties/freshness

**EXECUÇÃO**

Executar o DBT: `dbt source freshness`

**RESULTADO**

Foi usada a funcionalidade de checagem de `freshness` do DBT na source `origem_db.vendas`. Ao executar o comando acima, é esperado um `WARN` se a data da venda mais recente for mais antiga que 1 dia e um `ERROR STALE` se mais antiga que 365 dias.

O uso de `filter` para cálculo do `freshness` é útil para reduzir volume de dados processado.

A configuração `loaded_at_field` precisa necessariamente ter um timestamp em UTC, por isso, foi incluída a conversão, CONVERT_TZ no caso do MySQL.

---

### DBT Tests

Referência: https://docs.getdbt.com/docs/building-a-dbt-project/tests

Para exemplificar o uso, foi criado no diretório `tests` a consulta `test_valor_produto_le_100`.

O argumento `--store-failures` pode ser usado para fazer com que sejam registrados em uma tabela no banco os registros que fizeram testes falharem. Isso pode agilizar o desenvolvimento. Entretando, sem usar esta cláusula, o aruqivo `target` é gerado e também pode ajudar no debug.

- NOTAS:
    - É uma boa prática fazer testes para evitar SQL INJECTION quando se usa `seeds`. Foi criado um teste para isso no diretório `tests\generic` chamado `assert_sql_injection_prevention.sql`. Este teste é aplicado a cada uma das colunas necessárias dos seeds no arquivo de configuração `seeds.yml`.
    - Para rodar apenas um teste, usar o nome do teste: `dbt test --select sql_injection_prevention_produtos_desconto_coluna_string_para_teste`
    - Para rodar todos os testes de um modelo, usar o nome do modelo: `dbt test --select produtos_desconto`

**EXECUÇÃO**

Executar o DBT: `dbt test` ou `dbt test --store-failures`

**RESULTADO**

Se existir 1 ou mais produtos com valor unitário MENOR ou IGUAL a 100.00, o teste irá falhar.

Se existir algum regitro no modelo `produtos_desconto` carregado do seed com strings nos padrões proibidos pelo teste de `sql_injection`, o teste irá falhar.

---

### DBT Documentação do fluxo

Referência: https://docs.getdbt.com/docs/building-a-dbt-project/documentation
Referência: https://docs.getdbt.com/reference/commands/cmd-docs

Ainda que este projeto pessoal não tenha uma documentação extensiva de seus modelos, objetos e colunas, o DBT permite isso através das configurações nos arquivos `*.yml` adequados e também mardown `*.md` (ver documentação da ferramente nos links de referência acima).

Exemplo de documentação gerada: https://www.getdbt.com/mrr-playbook/#!/overview

- `dbt docs generate`: compila informações sobre o projeto nos arquivos `manifest.json` e `catalog.json`. Garantir que usou `dbt run` antes disso para ver documentação de todas as colunas e não somente as descritas explicitamente.
- `dbt docs serve`: cria um website local para navegar pela documentação. Para usar em uma porta diferente caso a 8080 padrão já esteja em uso: `dbt docs serve --port 8001`. O browser se abrirá automaticamente.

- NOTAS
    - O `Community Plugin` para MySQL usado neste projeto não usa a configuração `database` nos arquivos `profiles.yml` e `source.yml`. Para que o comando `dbt docs generate` funcionasse, precisei excluir esta configuração no `source.yml` e manter somente o `schema`

---

### DBT e orquestração no Airflow:

O caso de uso no link a seguir mostra como programar uma DAG que faz uso do arquivo `manifest.json` gerado pelo dbt para construir um fluxo de execução dos modelos e seus testes respeitando as dependências entre eles: 

__Use Case 2: dbt Core + Airflow at the Model Level__
https://www.astronomer.io/guides/airflow-dbt/#:~:text=Use%20Case%202%3A%20dbt%20Core%20%2B%20Airflow%20at%20the%20Model%20Level

Maiores detalhes podem ser encontrados na série de artigos abaixo:

Parte 1 - [airflow-dbt-1](https://www.astronomer.io/blog/airflow-dbt-1)  
Parte 2 - [airflow-dbt-2](https://www.astronomer.io/blog/airflow-dbt-2)  
Parte 3 - [airflow-dbt-3](https://www.astronomer.io/blog/airflow-dbt-3)

---

### DBT Clean

O comando `dbt clean` apaga todas as tabelas especificadas no `clean-targets` do `dbt_project.yml`

---

## Utilidades para este projeto:

- No WSL2, iniciar o serviço do docker: `sudo service docker start`

   - É aconselhável usar o Portainer para gerenciar os containers de maneira visual: `https://localhost:9443/#!/2/docker/containers`
     - Usuário `admin` | Senha `adminadminadmin`

- Para subir somente o banco e a interface de administração: `docker-compose up --build -d db adminer`

- Usar o `Adminer` pode ajudar na administração do banco de dados `MySQL`: `http://localhost:8080/` (usuário `root` e senha definida no `docker-compose.yml`)

- Para conectar via CLI no MySQL, dentro do container do MySQL: `mysql -uroot -p` e inserir a senha quando solicitada

- Ao término do uso deste projeto, fazer a exclusão dos containers do MySQL e do Adminer via Portainer ou via comando: `docker rm --force --volumes dbt_sandbox_db_1 dbt_sandbox_adminer_1`

---

## Resumo de todos os comandos para fácil execução completa deste projeto:

```bash
# Sessão de início do docker no terminal:
docker-compose up

# Em outra sessão do terminal:
cd my_dbt_sandbox
dbt debug
dbt deps
python ../0_init_db.py
dbt run
python ../1_incremental_vendas.py
dbt run
dbt snapshot
dbt seed
dbt run
dbt run-operation macro_read_table_records
dbt source freshness
dbt test
dbt docs generate
dbt docs serve --port 8001
dbt clean

# Na sessão inicial do docker:
docker rm --force --volumes dbt_sandbox_db_1 dbt_sandbox_adminer_1
```

---

## Referências interessantes:

- Checar se tabela existe: https://discourse.getdbt.com/t/writing-packages-when-a-source-table-may-or-may-not-exist/1487

- Jinja reference: https://docs.getdbt.com/reference/dbt-jinja-functions/adapter#get_relation

- Jinja reference: https://jinja.palletsprojects.com/en/3.0.x/templates/