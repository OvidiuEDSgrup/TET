
CREATE PROCEDURE wOPInvalidareLocMunca @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE @utilizator varchar(50), @lm varchar(20), @cod_invalidare varchar(1),
		@data datetime, @anulare bit, @xml xml

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	
	SELECT @lm = ISNULL(@parXML.value('(/row/@lm)[1]', 'varchar(20)'), ''),
		@cod_invalidare = ISNULL(@parXML.value('(/row/@cod_invalidare)[1]', 'varchar(1)'), ''),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@anulare = ISNULL(@parXML.value('(/row/@anulare)[1]', 'bit'), 0)
	
	/** Validari */
	IF @lm = ''
		RAISERROR('Loc de munca inexistent!', 16, 1)

	IF @cod_invalidare = ''
		RAISERROR('Tipul de invalidare nu este completat. Va rugam selectati una din cele doua valori posibile!', 16, 1)
	
	IF OBJECT_ID('tempdb.dbo.#tempCatalog') IS NOT NULL
		DROP TABLE #tempCatalog

	/** Luam locurile de munca inferioare (daca exista) celui selectat si lucram cu tabela #tempCatalog */
	;WITH locuriDeMunca
	AS 
	( 
		SELECT RTRIM(Cod) AS cod, detalii, ISNULL(detalii.value('(/row/@invalid)[1]', 'varchar(100)'), '') AS invalid, 1 AS nivel
		FROM lm WHERE lm.Cod = @lm
		UNION ALL
		SELECT RTRIM(l.Cod) AS cod, l.detalii, ISNULL(l.detalii.value('(/row/@invalid)[1]', 'varchar(100)'), '') AS invalid, ldm.nivel + 1 AS nivel
		FROM lm l
		INNER JOIN locuriDeMunca ldm ON ldm.cod = l.Cod_parinte
	)
	SELECT * INTO #tempCatalog FROM locuriDeMunca

	/** Trimitem parametrii la procedura de invalidare, care va scrie in detalii */
	SET @xml =
	(
		SELECT @cod_invalidare AS cod_invalidare, @data AS data, @anulare AS anulare FOR XML RAW
	)
	EXEC invalideazaObiectCatalog @sesiune = @sesiune, @parXML = @xml

	/** In final, facem update la tabela reala "lm" */
	UPDATE lm SET lm.detalii = l.detalii
	FROM lm lm
	INNER JOIN #tempCatalog l ON l.cod = lm.Cod

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
