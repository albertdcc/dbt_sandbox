import sqlalchemy as db
from faker import Faker
from datetime import date
import random

user = 'root'
pwd = 'root#msql452A'
server = '127.0.0.1:3306' # No Docker do Ubuntu, fica exposto como localhost (127.0.0.1)
database_name = 'dbt_sandbox_origem_db'

engine = db.create_engine(f'mysql://{user}:{pwd}@{server}', echo = True)
engine.execute(f"USE {database_name}")

meta = db.MetaData(schema=database_name)

clientes = db.Table('clientes', meta, autoload=True, autoload_with=engine)
vendedores = db.Table('vendedores', meta, autoload=True, autoload_with=engine)
produtos = db.Table('produtos', meta, autoload=True, autoload_with=engine)
vendas = db.Table('vendas', meta, autoload=True, autoload_with=engine)

fake = Faker()

connection = engine.connect()


#Inserting many records at ones
query = db.select([clientes.columns.id])
ResultProxy = connection.execute(query)
ResultSet = ResultProxy.fetchall()
clientes_id_list = [r[0] for r in ResultSet]

query = db.select([vendedores.columns.matricula])
ResultProxy = connection.execute(query)
ResultSet = ResultProxy.fetchall()
vendedores_id_list = [r[0] for r in ResultSet]

query = db.select([produtos.columns.codigo, produtos.columns.valor])
ResultProxy = connection.execute(query)
ResultSet = ResultProxy.fetchall()
produtos_id_vlr_list = [(r[0],r[1]) for r in ResultSet]

# Gerando dados para vendas:
vendas_list = []
for _ in range (100):
   id_cliente = clientes_id_list[random.randrange(0, len(clientes_id_list))]
   data_venda = fake.date_between(date.fromisoformat('2022-02-01'),date.fromisoformat('2022-03-01'))
   matricula_vendedor = vendedores_id_list[random.randrange(0, len(vendedores_id_list))]
   produto_aleatorio = random.randrange(0, len(produtos_id_vlr_list))
   codigo_produto = produtos_id_vlr_list[produto_aleatorio][0]
   valor_produto = produtos_id_vlr_list[produto_aleatorio][1]
   quantidade = random.randrange(1, 10)
   vendas_list.append({
      'id_cliente': id_cliente, 
      'data_venda': data_venda,
      'matricula_vendedor': matricula_vendedor, 
      'codigo_produto': codigo_produto,
      'qtde': quantidade,
      'valor_total': quantidade * valor_produto})
query = db.insert(vendas) 
ResultProxy = connection.execute(query,vendas_list)

print("Fim")