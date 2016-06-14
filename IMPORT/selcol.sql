drop procedure yso_selcol 
go
create procedure yso_selcol (@tabela sysname) as

--DECLARE @tabela sysname
--set @tabela='pozdoc'
DECLARE @listStr VARCHAR(MAX), @condStr varchar(max), @selisnullStr varchar(max), @updStr varchar(max)
SELECT @listStr = COALESCE(@listStr+', ' ,'') + rtrim(sc.name)
	,@condStr = COALESCE(@condStr+' and ' ,'') + 'd.'+rtrim(sc.name)+'=t.'+rtrim(sc.name)
	,@updStr = COALESCE(@updStr+', ' ,'') +rtrim(sc.name)+'=t.'+rtrim(sc.name)
	,@selisnullStr = COALESCE(@selisnullStr+', ','') 
	+rtrim(sc.name)
	+'=isnull('
	+CASE WHEN sc.system_type_id IN (167,175,231) and 1=0 THEN 'rtrim('+rtrim(sc.name)+')' ELSE rtrim(sc.name) END
	+','''')'
FROM sys.columns sc join sys.objects so on sc.object_id=so.object_id
WHERE so.object_id=object_id(@tabela) --so.name=@tabela 

--select object_definition (object_id(@tabela))
select @listStr, @condStr, @selisnullStr, @updStr
go
select sc.* 
FROM sys.columns sc join sys.objects so on sc.object_id=so.object_id
WHERE so.name='yso_vIaCodvama'
