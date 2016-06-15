--***
create procedure wScriuGrupeUtilizator (@sesiune varchar(50), @parXML xml)
as
begin
--set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	declare @utilizatorRia varchar(50), @grupa varchar(50), @update bit
	select	@utilizatorRia=@parXML.value('(/row/@utilizator)[1]','varchar(50)'),
			@grupa=@parXML.value('(/row/@grupa)[1]','varchar(50)'),
			@update=isnull(@parXML.value('(/row/@update)[1]','bit'),0)
			
	if not exists(select 1 from utilizatori u where id=@utilizatorRia)
		raiserror('Utilizator inexistent!',16,1)
	if not exists(select 1 from utilizatori u where id=@grupa and marca='GRUP')
		raiserror('Grup inexistent!',16,1)
	if @update=1 and not exists(select 1 from grupeUtilizatoriRia g where g.utilizator=@utilizatorRia)
		raiserror('Nu s-au identificat datele de modificat!',16,1)
		
	if exists(select 1 from fIaGrupeUtilizator(@utilizatorRia) f where f.grupa=@grupa)
		raiserror('Utilizatorul are asociat acest grup deja! (Fie direct fie prin intermediul altor grupuri!)',16,1)
	if exists(select 1 from fIaGrupeUtilizator(@grupa) f where f.grupa=@utilizatorRia)
		raiserror('Nu este permisa definirea circulara a grupelor!',16,1)
		
	if (@update=1)
		update g set grupa=@grupa from grupeUtilizatoriRia g where g.utilizator=@utilizatorRia
	else
		insert into grupeUtilizatoriRia(utilizator, grupa)
		select @utilizatorRia, @grupa
	
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wScriuGrupeUtilizator '+convert(varchar(20),ERROR_LINE())+')'
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
