--***
create procedure wpopRapInventar @sesiune varchar(50), @parxml xml
as
set transaction isolation level read uncommitted
declare @eroare varchar(1000)
begin try
	declare @utilizatorASiS varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	select	@parxml.value('(row/@idInventar)[1]','int') antetInventar
	for xml raw
end try
begin catch
	set @eroare=rtrim(ERROR_MESSAGE())+' (wpopRapInventar)'
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
