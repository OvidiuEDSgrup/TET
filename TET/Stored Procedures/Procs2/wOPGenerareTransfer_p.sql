
CREATE PROCEDURE wOPGenerareTransfer_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE
		@idContract INT, @mesaj VARCHAR(500), @utilizator VARCHAR(100), @gestiune VARCHAR(50), @numar VARCHAR(20), 
		@tipGestiune VARCHAR(1), @tipGestiuneRez VARCHAR(1),@subunitate VARCHAR(9), @gestiune_primitoare varchar(20)

	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)')
	SET @gestiune_primitoare = @parXML.value('(/*/@gestiune_primitoare)[1]', 'varchar(20)')


	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @Utilizator OUTPUT

	/** Validari **/
	IF @idContract IS NULL
		RAISERROR ('Nu s-a selectat nici o comanda!', 11, 1)

	/** Tip gestiune **/
	SELECT 
		@tipGestiune = tip_gestiune
	FROM gestiuni
	WHERE cod_gestiune = @gestiune

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	IF object_id('tempdb..#pozitiitransfer_p') IS NOT NULL
		DROP TABLE #pozitiitransfer_p

	SELECT idPozContract, cod, cantitate, convert(float,0.0) stoc, convert(float,0.0) detransferat
	INTO #pozitiitransfer_p
	FROM PozContracte
	WHERE idContract = @idContract

	IF object_id('tempdb..#calcStoc') IS NOT NULL
		DROP TABLE #calcStoc

	/** Stoc din gestiunea antetului **/
	SELECT pr.idPozContract idPozContract, sum(st.stoc) stoc
	INTO #calcStoc
	FROM stocuri st
	INNER JOIN #pozitiitransfer_p pr
		ON st.subunitate = @subunitate
			AND st.tip_gestiune = @tipGestiune
			AND st.cod_gestiune = @gestiune
			AND pr.cod = st.cod
	GROUP BY pr.idPozContract

	/**Se scrie stocul calculat in tabela de manevra **/
	UPDATE #pozitiitransfer_p
		SET #pozitiitransfer_p.stoc = cs.stoc
	FROM #calcStoc cs
	WHERE #pozitiitransfer_p.idPozContract = cs.idPozContract

	/** Se calculeaza cat ar mai fi de rezervat **/
	/*Aici ar trebui sa tina cont de cantitatea transferata pana acum. Nu de stoc. Momenta pun doar cantitatea.*/
	UPDATE #pozitiitransfer_p
		SET detransferat = cantitate
	
	/** Datele din grid **/
	SELECT (
			SELECT idPozContract, rtrim(pr.cod) AS cod, rtrim(n.denumire) AS denumire, convert(DECIMAL(15, 3), pr.cantitate) AS 
				cantitate, convert(DECIMAL(15, 3), pr.stoc) stoc, convert(DECIMAL(15, 3), pr.detransferat) detransferat
			FROM #pozitiitransfer_p pr
			INNER JOIN nomencl n
				ON n.cod = pr.cod
			FOR XML raw, type
			)
	FOR XML path('DateGrid'), root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareTransfer_p)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
