
/** Procedura de populare a machetei de raport de antecalculatie **/
CREATE PROCEDURE wPopulareAntecalculatie @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @id INT

SET @id = ISNULL(@parXML.value('(/row/@idAntec)[1]', 'int'), '')

SELECT @id AS 'Id_antec'
FOR XML raw, root('Date')
