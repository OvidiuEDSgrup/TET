--***

create procedure wpopRapPredare @sesiune varchar(50), @parXML xml
as
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @eroare varchar(1000)
begin try
	declare @utilizatorASiS varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	select	 @parxml.value('(row/@numar)[1]','varchar(50)') numar,
		convert(char(10),@parxml.value('(row/@data)[1]','datetime'),101) data
		
	for xml raw
end try
begin catch
	set @eroare=rtrim(ERROR_MESSAGE())+' (wpopRapPredare)'
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
