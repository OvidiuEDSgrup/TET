
CREATE PROCEDURE wOPInvalidareProdusNomenclator_p @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @cod varchar(20), @invalid varchar(100), @detalii xml

	SELECT @cod = @parXML.value('(/row/@cod)[1]', 'varchar(20)')
	SELECT TOP 1 @invalid = detalii.value('(/row/@invalid)[1]', 'varchar(100)')
	FROM nomencl WHERE Cod = @cod

	SELECT @invalid AS invalid
	FOR XML RAW, ROOT('Date')

END
