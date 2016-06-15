
create procedure wStergPozListaCoduriBare @sesiune varchar(50), @parXML xml
as

	declare @utilizator varchar(100), @cod varchar(20)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	set @cod=@parXML.value('(/*/@cod)[1]','varchar(20)')

	delete from temp_ListareCodBare where utilizator=@utilizator and cod=@cod

	exec wIaPozListaCoduriBare @sesiune=@sesiune, @parXML=@parXML
