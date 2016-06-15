--***
create procedure wpopRapAnexaContracte @sesiune varchar(50), @parxml xml
as
set transaction isolation level read uncommitted
declare @eroare varchar(1000)
begin try
	declare @utilizatorASiS varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	select	@parxml.value('(row/@tert)[1]','varchar(13)') tert,
		convert(char(10),dbo.boy(GETDATE()),101) datajos,
		convert(char(10),dbo.eoy(GETDATE()),101) datasus,
		@parxml.value('(row/@numar)[1]','varchar(20)') contract	,
		convert(char(10),@parxml.value('(row/@data)[1]','datetime'),101) data_contract		
	for xml raw
end try
begin catch
	set @eroare=rtrim(ERROR_MESSAGE())+' (wpopRapAnexaContracte)'
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
