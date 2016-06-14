drop procedure yso_condcol 
go
create procedure yso_condcol (@tabela sysname) as

--DECLARE @tabela sysname
--set @tabela='pozdoc'
DECLARE @listStr VARCHAR(MAX),@listStrNull VARCHAR(MAX)
SELECT @listStr = COALESCE(@listStr+', ' ,'')+rtrim(c.name)
	,@listStrNull = COALESCE(@listStrNull+' and ' ,'') + 'isnull(x.'+rtrim(c.name)+','''''''')='+'isnull(t.'+rtrim(c.name)+','''''''')'
FROM sys.index_columns ic 
	join sys.indexes i on i.index_id=ic.index_id and i.object_id=ic.object_id
	join sys.columns c on c.column_id=ic.column_id and c.object_id=ic.object_id
	join sys.objects o on c.object_id=o.object_id 
WHERE o.name=@tabela and i.name='modificabile'

select @listStr,@listStrNull 

go
select * from sys.objects o where o.name='yso_vIaPreturiNomenclator'
select * from sys.indexes i where i.name='modificabile'

