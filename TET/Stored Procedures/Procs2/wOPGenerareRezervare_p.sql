
CREATE PROCEDURE wOPGenerareRezervare_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@idContract INT, @mesaj VARCHAR(500), @cuRezervari INT, @gestiuneRezervari VARCHAR(20), @utilizator VARCHAR(100), 
		@dentert VARCHAR(50), @gestiune VARCHAR(50), @numar VARCHAR(20), @tipGestiune VARCHAR(1), @tipGestiuneRez VARCHAR(1), 
		@subunitate VARCHAR(9)

	select
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)')

	/** Parametri **/
	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRezervari OUTPUT, 0, @gestiuneRezervari OUTPUT
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @Utilizator OUTPUT

	/** Tipuri gestiuni **/
	SELECT	
		@tipGestiune = (CASE WHEN cod_gestiune = @gestiune THEN tip_gestiune ELSE isnull(@tipGestiune, '') END), 
		@tipGestiuneRez = (CASE WHEN cod_gestiune = @gestiuneRezervari THEN tip_gestiune ELSE isnull(@tipGestiuneRez, '') END)
	FROM gestiuni
	WHERE cod_gestiune IN (@gestiuneRezervari, @gestiune)

	/** Validari **/
	IF @idContract IS NULL
		RAISERROR ('Nu s-a selectat nici o comanda!', 11, 1)

	IF @cuRezervari = 0 OR @gestiuneRezervari IS NULL
		RAISERROR ('Nu este configurat lucrul cu gestiuni de rezervari', 11, 1)

	/** Date "antet" operatie **/
	SELECT 
		@idContract idContract, @dentert dentert, @numar numar, convert(varchar(10), GETDATE(),101) as data,
		@gestiune dengestiune, @gestiuneRezervari gestiunerezervari
	FOR XML raw, root('Date')

	/** Constructie date pozitie, cu stoc in gestiunea antetului, si stoc rezervat, samd **/
	IF object_id('tempdb..#pozitiiRezervare_p') IS NOT NULL
		DROP TABLE #pozitiiRezervare

	SELECT idPozContract, cod, cantitate, 0 stoc, 0 rezervat, 0 derezervat
	INTO #pozitiiRezervare_p
	FROM PozContracte
	WHERE idContract = @idContract

	IF object_id('tempdb..#calcStoc') IS NOT NULL
		DROP TABLE #calcStoc

	/** Stoc din gestiunea antetului **/
	SELECT @gestiune gestiune, pr.idPozContract idPozContract, sum(st.stoc) stoc
	INTO #calcStoc
	FROM stocuri st
	INNER JOIN #pozitiiRezervare_p pr
		ON st.subunitate = @subunitate
			AND st.tip_gestiune = @tipGestiune
			AND st.cod_gestiune = @gestiune
			AND pr.cod = st.cod
	GROUP BY pr.idPozContract

	/** Stoc rezervat deja-> calculat pe baza legaturilor prin idPozContract (PozContracte -> LegaturiContracte-> PozDoc ) **/
	INSERT INTO #calcStoc (gestiune, idPozContract, stoc)
	SELECT @gestiuneRezervari, pc.idPozContract, SUM(pd.cantitate)
	FROM PozContracte pc
	INNER JOIN LegaturiContracte lc ON pc.idPozContract = lc.idPozContract AND pc.idContract = @idContract
	INNER JOIN PozDoc pd ON pd.idPozDoc = lc.idPozDoc AND pd.Gestiune_primitoare = @gestiuneRezervari AND pd.Tip = 'TE'
	GROUP BY pc.idPozContract

	/**Se scrie stocul calculat in tabela de manevra **/
	UPDATE #pozitiiRezervare_p
		SET #pozitiiRezervare_p.stoc = cs.stoc
	FROM #calcStoc cs
	WHERE #pozitiiRezervare_p.idPozContract = cs.idPozContract
		AND cs.gestiune = @gestiune

	UPDATE #pozitiiRezervare_p
		SET #pozitiiRezervare_p.rezervat = cs.stoc
	FROM #calcStoc cs
	WHERE #pozitiiRezervare_p.idPozContract = cs.idPozContract
		AND cs.gestiune = @gestiuneRezervari

	/** Se calculeaza cat ar mai fi de rezervat **/
	UPDATE #pozitiiRezervare_p
		SET derezervat = (CASE WHEN cantitate - rezervat < stoc THEN cantitate - rezervat ELSE stoc END)
	where cantitate - rezervat > 0 and stoc > 0

	/** Datele din grid **/
	SELECT (
			SELECT 
				idPozContract, rtrim(pr.cod) AS cod, rtrim(n.denumire) AS denumire, convert(DECIMAL(15, 2), pr.cantitate) AS 
				cantitate, convert(DECIMAL(15, 2), pr.stoc) stoc, convert(DECIMAL(15, 2), pr.rezervat) rezervat, 
				convert(DECIMAL(15, 2), pr.derezervat) derezervat
			FROM #pozitiiRezervare_p pr
			INNER JOIN nomencl n
				ON n.cod = pr.cod
			FOR XML raw, type
			)
	FOR XML path('DateGrid'), root('Mesaje')
END TRY

BEGIN CATCH
	select '1' as inchideFereastra for xml raw, root('Mesaje')
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareRezervare_p)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
