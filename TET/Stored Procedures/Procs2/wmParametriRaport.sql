
CREATE PROCEDURE wmParametriRaport @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @itemID UNIQUEIDENTIFIER, @nume VARCHAR(200), @path VARCHAR(1000)

SET @itemID = @parXML.value('(/row/@itemID)[1]', 'uniqueidentifier')

SELECT @nume = NAME, @path = path
FROM ReportServer..CATALOG
WHERE ItemID = @itemID

SELECT convert(XML, parameter)
FROM ReportServer..CATALOG
WHERE ItemID = @itemID
FOR XML path('Date')

SELECT @nume AS titlu, @itemID AS itemID, @nume AS nume
FOR XML raw, root('Mesaje')
