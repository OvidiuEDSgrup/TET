--***
create procedure wStergGrupeUtilizator (@sesiune varchar(50), @parXML xml)
as
begin
--set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	declare @utilizatorRia varchar(50), @grupa varchar(50)
	select	@utilizatorRia=@parXML.value('(row/@utilizator)[1]','varchar(50)'),
			@grupa=@parXML.value('(/row/@grupa)[1]','varchar(50)')
	
	if not exists(select 1 from utilizatori u where id=@utilizatorRia)
		raiserror('Utilizator inexistent!',16,1)
	if not exists(select 1 from grupeUtilizatoriRia g where g.utilizator=@utilizatorRia)
		raiserror('Nu s-au identificat datele de sters!',16,1)
		
	delete gr
	from grupeUtilizatoriRia gr-- inner join utilizatori u on gr.grupa=u.ID and u.marca='GRUP'
	where gr.utilizator=@utilizatorRia and  gr.grupa=@grupa

end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wStergGrupeUtilizator '+convert(varchar(20),ERROR_LINE())+')'
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
