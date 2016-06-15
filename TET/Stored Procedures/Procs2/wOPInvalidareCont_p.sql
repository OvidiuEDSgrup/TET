
CREATE PROCEDURE wOPInvalidareCont_p @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @cont varchar(20), @invalid varchar(100), @detalii xml

	SELECT @cont = @parXML.value('(/row/@cont)[1]', 'varchar(20)')
	SELECT TOP 1 @invalid = detalii.value('(/row/@invalid)[1]', 'varchar(100)')
	FROM conturi WHERE Cont = @cont

	SELECT @invalid AS invalid
	FOR XML RAW, ROOT('Date')

END
