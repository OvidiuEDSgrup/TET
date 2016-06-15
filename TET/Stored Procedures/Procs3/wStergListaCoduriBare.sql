
CREATE PROCEDURE wStergListaCoduriBare @sesiune VARCHAR(50), @parXML XML
AS

	declare @utilizator varchar(100),@cod varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	select
		@cod=@parXML.value('(/*/@cod)[1]','varchar(20)')


	delete from temp_ListareCodBare where utilizator=@utilizator and cod=@cod
