
CREATE PROCEDURE wOPPreluareFacturiInOrdineDePlata_p @sesiune VARCHAR(50), @parXML XML
AS
	
	SELECT '' cont, convert(varchar(10),GETDATE(),101) data, '' explicatii, '' tert 
	FOR XML RAW, root('Date')
