
CREATE PROCEDURE wOPSchimbareStareOrdinePlata_p @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @stare varchar(20)
	SELECT @stare = @parXML.value('(/row/@stare)[1]', 'varchar(20)')

	SELECT @stare AS stare, 'Operat' AS stare_noua
	FOR XML RAW
END
