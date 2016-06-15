--***
create procedure wpopRapFormFactura @sesiune varchar(50), @parxml xml
as
set transaction isolation level read uncommitted
declare @eroare varchar(1000)
set @eroare=''
begin try
	declare @utilizatorASiS varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	declare @tip varchar(2), @numar varchar(50), @data datetime
	select	@tip=@parxml.value('(row/@tip)[1]','varchar(2)'),
			@numar=@parxml.value('(row/@numar)[1]','varchar(50)'),
			@data=@parxml.value('(row/@data)[1]','datetime')
	select @tip as tip, @numar as numar, convert(varchar(20),@data,101) as data,1 as nrExemplare for xml raw
end try
begin catch
	set @eroare='wpopRapFormFactura:'+
		char(10)+rtrim(ERROR_MESSAGE())
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
