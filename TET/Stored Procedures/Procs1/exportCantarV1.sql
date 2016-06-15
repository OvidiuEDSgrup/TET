--***
CREATE proc [dbo].[exportCantarV1] @sesiune varchar(50), @parxml xml
as
--go
declare @sql varchar(8000)
select @sql = 'bcp "exec ghita..apelCantarV1'''', ''<row/>'' " queryout "C:\exportCantar.txt" -T -S . -c -t,'
--select @sql
exec master..xp_cmdshell @sql
select 'exportCantar.txt' as fisier, 'wTipFormular' as numeProcedura ,
	1 as dialogSalvare
for xml raw, root('Mesaje') 

