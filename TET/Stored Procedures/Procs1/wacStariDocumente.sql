--***
create procedure wacStariDocumente (@sesiune varchar(50), @parXML xml)
as
begin
--set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	declare @tip varchar(100), @cod varchar(100), @denumire varchar(1000)
	select	@tip=@parxml.value('(/row/@tip)[1]','varchar(100)'),
			@cod=@parxml.value('(/row/@searchText)[1]','varchar(100)'),
			@denumire='%'+isnull(replace(@parxml.value('(/row/@searchText)[1]','varchar(100)'),' ','%'),'')+'%'
	select denumire as denumire, stare as cod, (case when modificabil=1 then 'Modificabil' else 'Nemodificabil' end) as info
	from staridocumente
	where tipDocument=@tip
		and (stare=@cod or denumire like @denumire)
		for xml raw
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' ('+ OBJECT_NAME(@@PROCID)+')'
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
