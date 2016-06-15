--***
create procedure wOPSchimbareStareDocument (@sesiune varchar(50), @parXML xml)
as
begin
--set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select @parXML=
	(select	@parxml.value('(/parametri/@tip)[1]','varchar(100)') tip,
			@parxml.value('(/parametri/@numar)[1]','varchar(100)') numar,
			@parxml.value('(/parametri/@data)[1]','varchar(100)') data,
			@parxml.value('(/parametri/@explicatii_stare_jurnal)[1]','varchar(100)') explicatii,
			@parxml.value('(/parametri/@stare_jurnal)[1]','varchar(100)') stare
	for xml raw)
	
	exec wScriuJurnalDocument @sesiune=@sesiune, @parXML=@parXML
	
end try
begin catch
	select @eroare=error_message()+' ('+ OBJECT_NAME(@@PROCID)+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end

/*
	if object_id('tempdb..#test') is not null
	begin
		select * from #test
		drop table #test
	end
*/
