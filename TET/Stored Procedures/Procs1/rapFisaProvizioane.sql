
/**
	Exemplu apel:

		EXEC rapFisaProvizioane @sesiune = '',
			@datajos = '2014-01-01',
			@datasus = '2015-04-03',
			@cont = NULL,
			@tert = NULL, --'999998',
			@factura = NULL, --'ABO26891',
			@locm = NULL

*/
CREATE PROCEDURE rapFisaProvizioane (
	@sesiune varchar(50),
	@datajos datetime,
	@datasus datetime,
	@cont varchar(20) = NULL, --> Filtru cont provizion
	@tert varchar(50) = NULL, --> Filtru tert financiar
	@factura varchar(20) = NULL, --> Filtru pe factura
	@locm varchar(20) = NULL --> Filtru pe loc de munca cu LIKE
)
AS
BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @utilizator varchar(20)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	/** Sold initial: luam ultimul rulaj si calculam soldul initial */
	SELECT MAX(p.datalunii) AS data, CONVERT(decimal(15,3), 0) AS sold_initial, p.tert, p.factura
	INTO #soldi
	FROM Provizioane p
	WHERE p.datalunii < @datajos
		AND p.idPozNCon IS NOT NULL --> doar provizioanele care au corespondent in Pozncon
		AND (ISNULL(@tert, '') = '' OR p.tert = @tert)
		AND (ISNULL(@factura, '') = '' OR p.factura = @factura)
		AND (ISNULL(@cont, '') = '' OR p.cont LIKE @cont + '%')
	GROUP BY p.tert, p.factura

	UPDATE s
	SET sold_initial = ROUND(p.debit - p.credit, 2)
	FROM #soldi s
	INNER JOIN Provizioane p ON p.datalunii = s.data AND p.tert = s.tert AND p.factura = s.factura

	/** Select-ul principal */
	SELECT p.datalunii, RTRIM(p.tert) AS tert, RTRIM(t.Denumire) AS dentert, p.factura, CONVERT(decimal(6,2), p.procent) AS procent,
		RTRIM(p.cont) AS cont, RTRIM(c.Denumire_cont) AS dencont, RTRIM(ISNULL(pdeb.Loc_munca, pcred.Loc_munca)) AS lm,
		RTRIM(lm.Denumire) AS denlm, RTRIM(ISNULL(pdeb.Tip, pcred.Tip)) AS tip_doc, RTRIM(ISNULL(pdeb.Numar, pcred.Numar)) AS numar_doc,
		CONVERT(varchar(10), ISNULL(pdeb.Data, pcred.Data), 103) AS data_doc, CONVERT(varchar(10), f.Data, 103) AS data_facturii,
		ISNULL(s.sold_initial, 0) AS sold_initial, ISNULL(CONVERT(decimal(15,3), pdeb.Suma), 0) AS rulaj_debit,
		ISNULL(CONVERT(decimal(15,3), pcred.Suma), 0) AS rulaj_credit, CONVERT(decimal(15,3), 0) AS sold_final,
		RTRIM(pdeb.Cont_debitor) AS cont_debitor, RTRIM(pcred.Cont_creditor) AS cont_creditor,
		CONVERT(decimal(15,3), f.Valoare + f.TVA_11 + f.TVA_22) AS valoarecutva,
		ROW_NUMBER() OVER (PARTITION BY p.tert, p.factura ORDER BY p.factura, p.datalunii) AS idLinie
	INTO #final
	FROM Provizioane p
	LEFT JOIN #soldi s ON s.tert = p.tert AND s.factura = p.factura
	LEFT JOIN facturi f ON f.Tert = p.tert AND f.Factura = p.factura
	LEFT JOIN terti t ON t.Subunitate = '1' AND p.tert = t.Tert
	LEFT JOIN pozncon pdeb ON pdeb.idPozncon = p.idPozncon AND pdeb.Cont_debitor LIKE '6%'
	LEFT JOIN pozncon pcred ON pcred.idPozncon = p.idPozNCon AND pcred.Cont_creditor LIKE '7%'
	LEFT JOIN conturi c ON c.Cont = p.cont
	LEFT JOIN lm ON lm.Cod = ISNULL(pdeb.Loc_munca, pcred.Loc_munca)
	WHERE p.datalunii BETWEEN @datajos AND @datasus
		AND p.idPozNCon IS NOT NULL
		AND (ISNULL(@tert, '') = '' OR p.tert = @tert)
		AND (ISNULL(@factura, '') = '' OR p.factura = @factura)
		AND (ISNULL(@locm, '') = '' OR pdeb.Loc_munca LIKE @locm + '%' OR pcred.Loc_munca LIKE @locm + '%')
	ORDER BY p.factura, p.datalunii
	
	/** Calculam recursiv soldul initial si final in functie de rulaje. */
	UPDATE #final
	SET sold_final = sold_initial + rulaj_debit - rulaj_credit
	WHERE idLinie = 1

	;WITH cte AS
	(
		SELECT f1.idLinie, CONVERT(decimal(15,3), f1.sold_initial) AS sold_initial, f1.rulaj_debit, f1.rulaj_credit, f1.sold_final,
			f1.tert, f1.factura
		FROM #final f1
		WHERE f1.idLinie = 1
		UNION ALL
		SELECT f2.idLinie, CONVERT(decimal(15,3), c.sold_final) AS sold_initial, f2.rulaj_debit, f2.rulaj_credit,
			CONVERT(decimal(15,3), c.sold_final + f2.rulaj_debit - f2.rulaj_credit) AS sold_final,
			f2.tert, f2.factura
		FROM #final f2
		INNER JOIN cte c ON f2.idLinie - 1 = c.idLinie
		WHERE c.tert = f2.tert AND c.factura = f2.factura
	)

	UPDATE f
	SET f.sold_initial = c.sold_initial, f.sold_final = c.sold_final
	FROM #final f
	INNER JOIN cte c ON c.idLinie = f.idLinie
	WHERE c.tert = f.tert AND c.factura = f.factura

	ALTER TABLE #final ADD soldi_factura float, soldf_factura float

	/** Sold initial la nivel de factura */
	UPDATE f
	SET f.soldi_factura = ISNULL(ff.sold_initial, 0)
	FROM #final f
	INNER JOIN
	(
		SELECT tert, factura, SUM(sold_initial) AS sold_initial
		FROM #final
		WHERE idLinie = 1
		GROUP BY tert, factura
	) AS ff ON ff.tert = f.tert AND ff.factura = f.factura

	/** Sold final la nivel de factura */
	UPDATE f
	SET f.soldf_factura = ISNULL(fff.sold_final, 0)
	FROM #final f
	INNER JOIN
	(
		SELECT MAX(idLinie) AS idLinie, tert, factura
		FROM #final
		GROUP BY tert, factura
	) AS ff ON ff.tert = f.tert AND ff.factura = f.factura
	CROSS APPLY
	(
		SELECT tert, factura, SUM(sold_final) AS sold_final
		FROM #final f1
		WHERE f1.tert = ff.tert AND f1.factura = ff.factura AND f1.idLinie = ff.idLinie
		GROUP BY f1.tert, f1.factura
	) AS fff
	WHERE fff.tert = f.tert AND fff.factura = f.factura

	/** Select final */
	SELECT * FROM #final

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500), @errorSeverity int, @errorState int
		SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
		SET @errorSeverity = ERROR_SEVERITY()
		SET @errorState = ERROR_STATE()
	RAISERROR(@mesajEroare, @errorSeverity, @errorState)
END CATCH
