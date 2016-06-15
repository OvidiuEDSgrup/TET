
CREATE PROCEDURE wOPAlocareTotMeniu_p @sesiune VARCHAR(50), @parXML XML
AS
SELECT 1 AS alocat, 1 AS dsterg, 1 AS dadaug, 1 AS dmodific, 1 AS doperatii, 1 AS dformulare
FOR XML raw, root('Date')
