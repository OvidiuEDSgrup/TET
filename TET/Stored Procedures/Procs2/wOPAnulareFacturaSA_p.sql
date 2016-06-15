/**
	Procedura de populare nr.doc. din JurnalDocumente,
	care e generat in pozdoc ca 'AP', pentru operatia de anulare factura din SAria
*/
CREATE PROCEDURE wOPAnulareFacturaSA_p @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE
		@numardoc varchar(20), @nrdeviz varchar(20)

	SET @nrdeviz = ISNULL(@parXML.value('(/row/@nrdeviz)[1]', 'varchar(20)'), '')

	SET @numardoc = (
		SELECT TOP 1
			RTRIM(jd.detalii.value('(/row/@nrdoc)[1]', 'varchar(20)')) AS nrdoc
		FROM JurnalDocumente jd
		INNER JOIN devauto dv ON dv.Cod_deviz = jd.numar
		WHERE dv.Cod_deviz = @nrdeviz
			AND jd.Stare = 3
		ORDER BY jd.data_operatii DESC
	)

	SELECT
		@numardoc AS nrdoc
	FOR XML RAW, ROOT('Date')

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
