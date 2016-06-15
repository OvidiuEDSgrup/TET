
CREATE PROCEDURE wOPInvalidareCont @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE @utilizator varchar(50), @cont varchar(20), @cod_invalidare varchar(1),
		@data datetime, @anulare bit, @xml xml

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	
	SELECT @cont = ISNULL(@parXML.value('(/row/@cont)[1]', 'varchar(20)'), ''),
		@cod_invalidare = ISNULL(@parXML.value('(/row/@cod_invalidare)[1]', 'varchar(1)'), ''),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@anulare = ISNULL(@parXML.value('(/row/@anulare)[1]', 'bit'), 0)
	
	/** Validari */
	IF @cont = ''
		RAISERROR('Cont inexistent!', 16, 1)

	IF @cod_invalidare = ''
		RAISERROR('Tipul de invalidare nu este completat. Va rugam selectati una din cele doua valori posibile!', 16, 1)
	
	IF OBJECT_ID('tempdb.dbo.#tempCatalog') IS NOT NULL DROP TABLE #tempCatalog

	/** Punem in tabela contul selectat in macheta + conturile inferioare lui */
	SELECT c.*, ISNULL(detalii.value('(/row/@invalid)[1]', 'varchar(100)'), '') AS invalid
	INTO #tempCatalog
	FROM conturi c
	INNER JOIN dbo.arbconturi(@cont) ac ON ac.Cont = c.Cont

	/** Trimitem parametrii la procedura de invalidare, care va scrie in detalii */
	SET @xml =
	(
		SELECT @cod_invalidare AS cod_invalidare, @data AS data, @anulare AS anulare FOR XML RAW
	)
	EXEC invalideazaObiectCatalog @sesiune = @sesiune, @parXML = @xml

	/** In final, facem update la tabela reala "conturi" */
	UPDATE c SET c.detalii = l.detalii
	FROM conturi c
	INNER JOIN #tempCatalog l ON l.Cont = c.Cont

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
