
CREATE PROCEDURE wIaFisiereOportunitate @sesiune VARCHAR(50), @parXML XML
AS

	DECLARE 
		@idOportunitate INT, @caleUpload VARCHAR(100), @f_fisier varchar(200)
	
	SET @idOportunitate = @parXML.value('(/*/@idOportunitate)[1]', 'int')
	SET @f_fisier = @parXML.value('(/*/@f_fisier)[1]', 'varchar(200)')

	SELECT 
		@caleUpload = rtrim(ltrim(val_alfanumerica)) + '/formulare/uploads/'
	FROM par
	WHERE Tip_parametru = 'AR' AND Parametru = 'URL'

	SELECT 
		RTRIM(fisier) AS fisier, RTRIM(observatii) AS observatii, '<a href="' + @caleUpload + rtrim(fisier) + '" target="_blank" /><u> Click </u></a>' AS download, idFisierOp idFisier
	FROM FisiereOportunitati
	WHERE idOportunitate = @idOportunitate
	FOR XML raw, root('Date')
