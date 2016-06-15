--***

CREATE proc [dbo].[exportCantarV2] @sesiune varchar(50), @parxml xml
as
--go
declare @sql varchar(8000)
select @sql = 'bcp "exec lactag..apelCantarV2 '''+@sesiune+''', ''<row/>'' " queryout "C:\SM192.168.1.101F37.DAT" -T -S . -c -t,'
--select @sql
exec master..xp_cmdshell @sql
--exec master..xp_cmdshell 'c:\digiwtcp.exe WR 37 192.168.1.xxx'

select 'SM192.168.1.101F37.DAT' as fisier, 'wTipFormular' as numeProcedura ,
	1 as dialogSalvare
for xml raw, root('Mesaje')

