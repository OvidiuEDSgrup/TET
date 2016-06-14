drop procedure yso_selcol 
go
create procedure yso_selcol (@tabela sysname) as

--DECLARE @tabela sysname
--set @tabela='pozdoc'
DECLARE @listStr VARCHAR(MAX)
SELECT @listStr = COALESCE(@listStr+', ' ,'') + rtrim(sc.name)
FROM sys.columns sc join sys.objects so on sc.object_id=so.object_id
WHERE so.name=@tabela 

select @listStr

