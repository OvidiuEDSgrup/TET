--***
CREATE proc [dbo].[exportCantarV3] @sesiune varchar(50), @parxml xml
as
--go
declare @sql varchar(8000)
exec apelCantarV3 @sesiune,'<row/>'

select @sql = 'bcp ##ptCantar out "D:\asisria\Frame\Formulare\dibalscopItems.dibal" -T -S . -c -t,'
--select @sql
exec master..xp_cmdshell @sql
select 'dibalscopItems.dibal' as fisier, 'wTipFormular' as numeProcedura ,
	1 as dialogSalvare
for xml raw, root('Mesaje') 
