
CREATE PROCEDURE wOPInvalidareGestiune_p @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @gestiune varchar(20), @invalid varchar(100), @detalii xml

	SELECT @gestiune = @parXML.value('(/row/@gestiune)[1]', 'varchar(20)')
	SELECT TOP 1 @invalid = detalii.value('(/row/@invalid)[1]', 'varchar(100)')
	FROM gestiuni WHERE Cod_gestiune = @gestiune

	SELECT @invalid AS invalid
	FOR XML RAW, ROOT('Date')

END
