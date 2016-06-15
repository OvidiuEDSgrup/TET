--***
create procedure wIaGrupeUtilizator (@sesiune varchar(50), @parXML xml)
as
begin
--set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	declare @utilizatorRia varchar(50)
	select @utilizatorRia=@parXML.value('(row/@utilizator)[1]','varchar(50)')
	
	select gr.utilizator as utilizator, u.ID as grupa, u.Nume as denumire
	from grupeUtilizatoriRia gr inner join utilizatori u on gr.grupa=u.ID and u.marca='GRUP'
	where gr.utilizator=@utilizatorRia
	for xml raw
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wIaGrupeUtilizator '+convert(varchar(20),ERROR_LINE())+')'
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
