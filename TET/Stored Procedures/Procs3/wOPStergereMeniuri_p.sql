--***
create procedure wOPStergereMeniuri_p @sesiune varchar(50), @parXML xml
as

--declare @meniu varchar()
/*
select	@parxml.value('(row/@meniu)[1]','@varchar(1000)'),
		@parxml.value('(row/@tip_m)[1]','@varchar(1000)'),
		@parxml.value('(row/@subtip_m)[1]','@varchar(1000)'),
		@parxml.value('(row/@sursa)[1]','@varchar(1000)')
*/
select @parXML=dbo.fInlocuireDenumireElementXML(@parXML, 'parametri')
if object_id('tempdb..#tipuri') is not null drop table #tipuri
	create table #tipuri(meniu varchar(20))
exec wOPGasesteRelatiiConfigurari_tabela @sesiune=@sesiune, @parXML=null
exec wOPGasesteRelatiiConfigurari @sesiune=@sesiune, @parXML=@parXML

select 1 as export for xml raw

select (select *, '#FF0000' culoare from #tipuri for xml raw, type)
FOR XML PATH('DateGrid'), ROOT('Mesaje')
if object_id('tempdb..#tipuri') is not null drop table #tipuri
--select 0 as stergcfg for xml raw
/*declare @eroare varchar(max)
select @eroare=''
begin try
	declare @meniu varchar(20)
	select @meniu=@parXML.value('(row/@meniu)[1]','varchar(20)')
	
	if @meniu is null
		raiserror('Selectati un meniu pentru stergere!',16,1)
end try
begin catch
	select @eroare=error_message()+' (wOPStergereMeniuri)'
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
*/
