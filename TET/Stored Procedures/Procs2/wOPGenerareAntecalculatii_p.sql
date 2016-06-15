
CREATE PROCEDURE wOPGenerareAntecalculatii_p @sesiune VARCHAR(50), @parXML XML
AS
	DECLARE 
		@fXML XML, @numarDoc VARCHAR(20), @utilizator VARCHAR(50)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	set @fXML= (select 'AT' tip, @utilizator utilizator for xml raw)
	EXEC wIauNrDocFiscale @parXML = @fXML, @Numar = @numarDoc OUTPUT

	SELECT @numarDoc AS numarDoc, convert(VARCHAR(10), GETDATE(), 101) AS data FOR XML raw, root('Date')
