
CREATE PROCEDURE wOPPreluareInOrdineDePlata_p @sesiune VARCHAR(50), @parXML XML
AS
SELECT @parXML
FOR XML path('Date')
