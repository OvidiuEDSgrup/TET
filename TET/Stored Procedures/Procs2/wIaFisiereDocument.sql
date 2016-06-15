
CREATE PROCEDURE wIaFisiereDocument @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE
		@tip varchar(2), @numar varchar(50), @data datetime, @caleUpload varchar(200)

	SELECT
		@tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)'),
		@numar = @parXML.value('(/row/@numar)[1]', 'varchar(50)'),
		@data = @parXML.value('(/row/@data)[1]', 'datetime')

	SELECT
		@caleUpload = RTRIM(LTRIM(val_alfanumerica)) + '/formulare/uploads/'
	FROM par
	WHERE Tip_parametru = 'AR'
		AND Parametru = 'URL'
	
	SELECT RTRIM(fisier) AS fisier, RTRIM(observatii) AS observatii, '<a href="' + @caleUpload + rtrim(fisier) + 
	'" target="_blank" /><u> Click </u></a>' AS download, idFisier
	FROM FisiereDocument
	WHERE numar = @numar
		AND tip = @tip
		AND data = @data
	FOR XML RAW, ROOT('Date')

END
