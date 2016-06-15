
CREATE PROCEDURE wOPCopiezUtilizatorED_p @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(10)

SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(10)')

SELECT '' AS utilizator, '' AS numeprenume, '' AS utilizatorwindows, @utilizator AS utilizatorsursa
FOR XML raw, root('Date')
