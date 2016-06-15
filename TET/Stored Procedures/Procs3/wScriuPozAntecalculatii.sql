
CREATE PROCEDURE wScriuPozAntecalculatii @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@idAntec INT, @idElement INT, @cod VARCHAR(20), @cantitate FLOAT, @data DATETIME, @valuta VARCHAR(10), @curs FLOAT, @update BIT, 
		@numarDoc VARCHAR(8), @fXML XML, @utilizator VARCHAR(20), @docGenerare XML, @pretElement FLOAT, @cantitateElement FLOAT, @mesaj VARCHAR(500), 
		@element VARCHAR(20), @tipElement VARCHAR(2), @scriuPret BIT, @detalii xml

	SET @valuta = ISNULL(@parXML.value('(/row/@valuta)[1]', 'varchar(20)'), '')
	SET @curs = ISNULL(@parXML.value('(/row/@curs)[1]', 'float'), 1)
	SET @cod = ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), '')
	SET @cantitate = ISNULL(@parXML.value('(/row/@cantitate)[1]', 'float'), 1)
	SET @curs = ISNULL(@parXML.value('(/row/@curs)[1]', 'float'), 1)
	IF @curs = 0
		SET @curs = 1

	SET @data = ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), 1)
	SET @idAntec = ISNULL(@parXML.value('(/row/@idAntec)[1]', 'int'), 0)
	SET @idElement = ISNULL(@parXML.value('(/row/row/@id)[1]', 'int'), 0)
	SET @tipElement = @parXML.value('(/row/row/@tip)[1]', 'varchar(2)')
	SET @element = @parXML.value('(/row/row/@cod)[1]', 'varchar(20)')

	IF isnull(@tipElement, '') <> 'E'
		SET @pretElement = ISNULL(@parXML.value('(/row/row/@pret)[1]', 'float'), 0)
	SET @cantitateElement = ISNULL(@parXML.value('(/row/row/@cantitate)[1]', 'float'), 0)
	SET @numarDoc = ISNULL(@parXML.value('(/row/@numarDoc)[1]', 'varchar(20)'), '')
	SET @update = ISNULL(@parXML.value('(/row/row/@update)[1]', 'bit'), 0)
	SET @scriuPret = ISNULL(@parXML.value('(/*/@scriuPret)[1]', 'bit'), 0)
	
	if @parXML.exist('(/*/detalii)[1]')=1
		SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	IF @update = 1
	BEGIN
		IF isnull(@tipElement, '') <> 'E'
		UPDATE pozAntecalculatii
			SET cantitate = @cantitateElement, pret = @pretElement
		WHERE id = @idElement

		SET @docGenerare = (SELECT @idAntec AS id, @data AS data, @numarDoc AS numarDoc, @cantitateElement procent, @element element, @scriuPret scriuPret, @detalii detalii FOR XML raw)

		EXEC GenerareAntecalculatii @sesiune = @sesiune, @parXML = @docGenerare
	END
	ELSE
		IF @update = 0
		BEGIN
			SET @fXML = '<row tip="AT"/>'
			SET @fXML.modify('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')

			EXEC wIauNrDocFiscale @parXML = @fXML, @Numar = @numarDoc OUTPUT

			SET @docGenerare = (SELECT @cod AS cod, @numarDoc AS numarDoc, @data AS data, @scriuPret scriuPret, @valuta valuta, @curs curs, @detalii detalii FOR XML raw,type)

			EXEC GenerareAntecalculatii @sesiune = @sesiune, @parXML = @docGenerare
			SELECT TOP 1 @idAntec = idAntec	FROM antecalculatii	WHERE numar = @numarDoc	AND cod = @cod AND convert(DATE, data) = @data ORDER BY idAntec DESC
		END

	DECLARE @docXMLIaPozAntec XML

	SET @docXMLIaPozAntec = (SELECT @idAntec AS idAntec	FOR XML raw	)

	EXEC wIaPozAntecalculatii @sesiune = @sesiune, @parXML = @docXMLIaPozAntec
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuPozAntecalculatii)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
