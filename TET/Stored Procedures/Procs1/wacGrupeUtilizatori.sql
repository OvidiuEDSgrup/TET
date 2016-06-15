--***
create procedure wacGrupeUtilizatori (@sesiune varchar(50), @parXML xml)
as
begin
--set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20), @searchText varchar(200)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	select @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(200)'),''),' ','%')+'%'
	
	select u.ID as cod, u.Nume as denumire
		from utilizatori u
	where u.marca='GRUP'
		and (u.id like @searchText or u.Nume like '%'+@searchText)
	for xml raw
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wacGrupeUtilizatori '+convert(varchar(20),ERROR_LINE())+')'
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
