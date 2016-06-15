
CREATE PROCEDURE wOPInvalidareGestiune @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE @utilizator varchar(50), @gestiune varchar(20), @cod_invalidare varchar(1),
		@data datetime, @anulare bit, @xml xml

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	
	SELECT @gestiune = ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'), ''),
		@cod_invalidare = ISNULL(@parXML.value('(/row/@cod_invalidare)[1]', 'varchar(1)'), ''),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@anulare = ISNULL(@parXML.value('(/row/@anulare)[1]', 'bit'), 0)
	
	/** Validari */
	IF @gestiune = ''
		RAISERROR('Gestiune inexistenta!', 16, 1)

	IF @cod_invalidare = ''
		RAISERROR('Tipul de invalidare nu este completat. Va rugam selectati una din cele doua valori posibile!', 16, 1)
	
	IF OBJECT_ID('tempdb.dbo.#tempCatalog') IS NOT NULL DROP TABLE #tempCatalog
	
	SELECT *, ISNULL(detalii.value('(/row/@invalid)[1]', 'varchar(100)'), '') AS invalid
	INTO #tempCatalog FROM gestiuni WHERE Cod_gestiune = @gestiune

	/** Trimitem parametrii la procedura de invalidare, care va scrie in detalii */
	SET @xml =
	(
		SELECT @cod_invalidare AS cod_invalidare, @data AS data, @anulare AS anulare FOR XML RAW
	)
	EXEC invalideazaObiectCatalog @sesiune = @sesiune, @parXML = @xml

	/** In final, facem update la tabela reala "gestiuni" */
	UPDATE g SET g.detalii = l.detalii
	FROM gestiuni g
	INNER JOIN #tempCatalog l ON l.Cod_gestiune = g.Cod_gestiune

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
