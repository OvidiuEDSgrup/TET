
CREATE PROCEDURE wIaFisiereAtasate @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @idContract INT, @caleUpload VARCHAR(100)

SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')

SELECT @caleUpload = rtrim(ltrim(val_alfanumerica)) + '/formulare/uploads/'
FROM par
WHERE Tip_parametru = 'AR'
	AND Parametru = 'URL'

SELECT RTRIM(fisier) AS fisier, RTRIM(observatii) AS observatii, '<a href="formulare/uploads/' + rtrim(fisier) + 
	'" target="_blank" /><u> Click </u></a>' AS download, idFisier
FROM FisiereContract
WHERE idContract = @idContract
FOR XML raw, root('Date')
