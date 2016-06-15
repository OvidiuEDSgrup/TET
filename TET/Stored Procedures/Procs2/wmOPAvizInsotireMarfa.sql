
CREATE PROCEDURE wmOPAvizInsotireMarfa @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE
		@xml xml, @raport varchar(50)

	SET @xml =
	(
		SELECT
			'AVMarfa' + REPLACE(CONVERT(varchar(10), GETDATE(), 103), '/', '') AS numeFisier,
			'/CG/Stocuri/Aviz stoc' AS caleRaport, DB_NAME() AS BD,
			CONVERT(varchar(10), GETDATE(), 120) AS data, NULL AS gestiune
		FOR XML RAW
	)

	EXEC wExportaRaport @sesiune = @sesiune, @parXML = @xml

	SELECT 'back(1)' AS actiune
	FOR XML RAW, ROOT('Mesaje')

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_ID(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
