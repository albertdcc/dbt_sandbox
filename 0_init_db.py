import sqlalchemy as db
from faker import Faker
from datetime import date
import random

user = 'root'
pwd = 'root#msql452A'
server = '127.0.0.1:3306' # No Docker do Ubuntu, fica exposto como localhost (127.0.0.1)
database_name = 'dbt_sandbox_origem_db'

engine = db.create_engine(f'mysql://{user}:{pwd}@{server}', echo = True)
engine.execute(f"DROP DATABASE IF EXISTS {database_name}")
engine.execute(f"CREATE DATABASE IF NOT EXISTS {database_name}") #create db

#engine.execute(f"SET GLOBAL TIME_ZONE = '-03:00'") #  Desnecessário após inclusão do `--default-time-zone="-03:00"` no docker-compose

# Ativa log de queries executadas na tabela ´mysql.general_log` (útil para debugar o que o DBT está fazendo)
engine.execute(f"SET GLOBAL log_output = 'TABLE'")
engine.execute(f"SET GLOBAL general_log = 'ON'")

engine.execute(f"USE {database_name}")

meta = db.MetaData(schema=database_name)

clientes = db.Table('clientes', meta,
   db.Column('id', db.Integer, db.Identity(), primary_key = True), 
   db.Column('nome', db.String(50))
)

vendedores = db.Table('vendedores', meta,
   db.Column('matricula', db.Integer, db.Identity(), primary_key = True), 
   db.Column('nome', db.String(50))
)

produtos = db.Table('produtos', meta,
   db.Column('codigo', db.Integer, db.Identity(), primary_key = True), 
   db.Column('nome', db.String(50)),
   db.Column('valor', db.Float, nullable = False)
)

vendas = db.Table('vendas', meta,
   db.Column('id', db.Integer, db.Identity(), primary_key = True),
   db.Column('data_venda', db.DateTime),
   db.Column('id_cliente', db.Integer),
   db.Column('matricula_vendedor', db.Integer),
   db.Column('codigo_produto', db.Integer),
   db.Column('qtde', db.Integer),
   db.Column('valor_total', db.Float, nullable = False),
   db.ForeignKeyConstraint(['id_cliente'], ['clientes.id']),
   db.ForeignKeyConstraint(['matricula_vendedor'], ['vendedores.matricula']),
   db.ForeignKeyConstraint(['codigo_produto'], ['produtos.codigo'])
)

meta.create_all(engine, checkfirst=True)

fake = Faker()

clientes_list = []
for _ in range(100):
   clientes_list.append({'nome': fake.name()[0:50]})

vendedores_list = []
for _ in range(10):
   vendedores_list.append({'nome': fake.name()[0:50]})

produtos_list = []
for _ in range(8):
   produtos_list.append({'nome': fake.catch_phrase()[0:50], 'valor': round(random.uniform(10.5, 750.5),2)})

connection = engine.connect()


#Inserting many records at ones
query = db.insert(clientes) 
ResultProxy = connection.execute(query,clientes_list)

query = db.insert(vendedores) 
ResultProxy = connection.execute(query,vendedores_list)

query = db.insert(produtos) 
ResultProxy = connection.execute(query,produtos_list)


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
for _ in range (500):
   id_cliente = clientes_id_list[random.randrange(0, len(clientes_id_list))]
   data_venda = fake.date_between(date.fromisoformat('2022-01-01'),date.fromisoformat('2022-02-01'))
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