
CREATE PROCEDURE wStergPozDateCentralizatorPlanificare @sesiune VARCHAR(50), @parXML XML
AS

	declare @id int

	set @id=@parXML.value('(/*/@idPlanificare)[1]','int')


	delete from planificare where id=@id


	exec wIaPozDateCentralizatorPlanificare @sesiune=@sesiune, @parXML=@parXML
