
CREATE PROCEDURE wOPPrefiltrareEtichete_p @sesiune VARCHAR(50), @parXML XML
AS
	
	select '' as denumire, '' as grupa, '' dengrupa for xml raw, root('Date')
