--nesse arquivos:
-- vamos tratar os dados para responder pergutnas sobre o relatorio de vendas

--Criando banco de dados
CREATE DATABASE Distribuidora
GO
--Usando o banco de dados
USE Distribuidora
GO
--Criando tabela Relatorio vendas
CREATE TABLE relatorio_vendas(
	 id	int
	,data	varchar(15)
	,loja	varchar(50)
	,produto	varchar(50)
	,quantidade	int
	,valor_uni	money
)
GO
-- inserindo dados
begin transaction

BULK INSERT #relatorio_vendas
FROM 'C:\Users\PAI\Downloads\relatorio_vendas.csv'
WITH(
	CODEPAGE = 'ACP',
	fieldterminator = ',',
	rowterminator ='\n'
)
--(15000 linhas afetadas)
commit

SELECT TOP (1000) [id]
      ,[data]
      ,[loja]
      ,[produto]
      ,[quantidade]
      ,[valor_uni]
  FROM [Distribuidora].[dbo].[relatorio_vendas]
  order by id
--1	| 5-18-2022		| Maranhão			| Caixa de som	| 4	| 79,00
--2	| 7-24-2022		| Santa Catarina	| Notebook		| 9	| 3789,00
--3	| 12-20-2022	| Rio de Janeiro	| Notebook		| 3	| 3789,00


select COUNT(DISTINCT(ID)) AS 'ID Unicos'
from relatorio_vendas

--ID Unicos
--15000

------------------------------------------------
--vamos converter a coluna data que esta em varchar para DATE
ALTER TABLE relatorio_vendas
ALTER COLUMN data date
-- Recebemos a seguinte mensagem
--Mensagem 241, Nível 16, Estado 1, Linha 51
--Falha ao converter data e/ou hora da cadeia de caracteres.
--A instrução foi finalizada.

-- vamos ter que explorar os dados e tratar para garantir sua integridade
------------------------------------------------
select len(data) as largura, count(data) as total
from relatorio_vendas
group by len(data)

-- temos dados em formato divergente na mesma coluna
--largura|	total
--	9	 |	9090
--	10	 |	2676
--	8	 |	3234

-- vamos invertigar
select top(1) id, data from relatorio_vendas where len(data) = 8
select top(1) id, data from relatorio_vendas where len(data) = 9
select top(1) id, data from relatorio_vendas where len(data) = 10
-- datas no formato 4-9-2022 ,5-18-2022,12-20-2022
-- vamos começar pela data com 10 digitos

UPDATE relatorio_vendas
set data = CONVERT(date, data, 110)
where len(data) = 10

-- (2676 linhas afetadas)
UPDATE relatorio_vendas
set data = CONVERT(date, data, 110)
where len(data) = 8
-- (3234 linhas afetadas)
UPDATE relatorio_vendas
set data = CONVERT(date, data, 110)
where len(data) = 9
--opá encontramos um obstáculo nas data com 9 caracteres
--Mensagem 241, Nível 16, Estado 1, Linha 35
--Falha ao converter data e/ou hora da cadeia de caracteres.
select id, data
from relatorio_vendas
where len(data) = 9
-- temos datas com 2 digitos no dia e 1 no mês(12-3-2022)
-- temos data com 1 digito no dia e 2 no mês(5-26-2022)
-- primeiro vamos tratar data com 1 digito no dia 

begin transaction
-- Adiciona um zero no início do dia
-- Vamos usar a função stuff()
-- nela passamos obrigatoriamente 4 parametros
--stuff('string a ser alterada=str',posisção inicial da alteração=int,quantidade de caracteres a ser removido=int,'caractere a ser incerido=str')
--stuff(data,1,0,'0')
UPDATE relatorio_vendas
SET data = stuff(data,1,0,'0') -- Adiciona um zero no início do dia
WHERE data LIKE '_-%%';
rollback
commit

-- Adiciona um zero no início do mês
begin transaction
UPDATE relatorio_vendas
SET data = stuff(data,4,0,'0')
WHERE data LIKE '%-_-%';
commit

--conferindo integridade
select len(data) as largura, count(data) as total
from relatorio_vendas
group by len(data)
-- data limpa
--largura|	total
--	10	 |	15000

select top(10) data, id
from relatorio_vendas

--	data		|	id
--	01-22-2022	|	4
--	2022-04-09	|	6  ok
--	temos dados onde o ano esta na frente
-- e temos dados onde o ano esta atrás

select id, concat('2022-',stuff(data,6,5,'')) as data_formatda-- com stuff estamos tirando '-2022' de trás
from relatorio_vendas-- com concat estamos colocando '2022-' na frente
where id = '4'
--id	|	data_formatada
--4		|	2022-01-22

--formatação deu certo agra vamos testar a nossa codição antes de alterar os dados
select top(5) id, data
from relatorio_vendas
where stuff(data,6,5,'') != '2022-'
--deu certo, podemos alterar
begin transaction

UPDATE relatorio_vendas
SET	Data = concat('2022-',stuff(data,6,5,''))
where stuff(data,6,5,'') != '2022-'


select TOP(100)id, data
from relatorio_vendas

COMMIT
-------------------------------------------------------
--após todas alterações feitas
-- ainda ssim nao conseguimos alterar o tipo da coluna para DATE
--Exportaremos os dados da coluna data para um arquivo CSV
select data from Distribuidora.dbo.relatorio_vendas
-- vamos abrir no EXCEL
-- ao usar a filtragem, descobrimos 11 linhas com a data 29/02/2022
-- foram excluida 11 linhas onde a data era 29/02/2022
-- sendo que em 2022 fevereiro teve somento 28 dias
DELETE FROM relatorio_vendas
WHERE data = '29/02/2022'
-- agora podemos converter a coluna de varchar para date
begin transaction
ALTER TABLE relatorio_vendas
ALTER COLUMN data DATE;
--
commit
----------------------
