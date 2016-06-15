
CREATE PROCEDURE wOPInvalidareProdusNomenclator @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE @utilizator varchar(50), @cod varchar(20), @cod_invalidare varchar(1),
		@data datetime, @anulare bit, @xml xml

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	
	SELECT @cod = ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''),
		@cod_invalidare = ISNULL(@parXML.value('(/row/@cod_invalidare)[1]', 'varchar(1)'), ''),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@anulare = ISNULL(@parXML.value('(/row/@anulare)[1]', 'bit'), 0)
	
	/** Validari */
	IF @cod = ''
		RAISERROR('Cod inexistent!', 16, 1)

	IF @cod_invalidare = ''
		RAISERROR('Tipul de invalidare nu este completat. Va rugam selectati una din cele doua valori posibile!', 16, 1)
	
	IF OBJECT_ID('tempdb.dbo.#tempCatalog') IS NOT NULL DROP TABLE #tempCatalog
	
	SELECT *, ISNULL(detalii.value('(/row/@invalid)[1]', 'varchar(100)'), '') AS invalid
	INTO #tempCatalog FROM nomencl WHERE Cod = @cod

	/** Trimitem parametrii la procedura de invalidare, care va scrie in detalii */
	SET @xml =
	(
		SELECT @cod_invalidare AS cod_invalidare, @data AS data, @anulare AS anulare FOR XML RAW
	)
	EXEC invalideazaObiectCatalog @sesiune = @sesiune, @parXML = @xml

	/** In final, facem update la tabela reala "nomencl" */
	UPDATE n SET n.detalii = l.detalii
	FROM nomencl n
	INNER JOIN #tempCatalog l ON l.Cod = n.Cod

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
