--***
create procedure wpopRapAnexaPenalitati @sesiune varchar(50), @parxml xml
as
set transaction isolation level read uncommitted
declare @eroare varchar(1000)
begin try
	declare @utilizatorASiS varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	select	@parxml.value('(row/@tert)[1]','varchar(13)') tert,
		convert(char(10),@parxml.value('(row/@datajos)[1]','datetime'),101) datajos,
		convert(char(10),@parxml.value('(row/@datasus)[1]','datetime'),101) datasus		
	for xml raw
end try
begin catch
	set @eroare=rtrim(ERROR_MESSAGE())+' (wpopRapAnexaPenalitati)'
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
