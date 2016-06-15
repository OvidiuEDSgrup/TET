
/*
	EXEC rapCostUnitar '', '2014-05-01', '2014-11-30', 'L', '113', null, 'N', '', NULL
*/

CREATE PROCEDURE rapCostUnitar @sesiune varchar(50), @datajos datetime, @datasus datetime, @grupare varchar(1),
	@lm char(9), @comanda char(13), @TipComanda varchar(1), @artcalc char(9), @produs varchar(50)
AS
BEGIN TRY
	DECLARE @subunitate varchar(20)
	SELECT @subunitate = RTRIM(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'SUBPRO'

	SELECT CONVERT(varchar(10), cs.data_lunii, 103) as data, cs.data_lunii AS datal, MAX(RTRIM(lm.Denumire)) AS denlm,
		RIGHT('0' + CONVERT(varchar(2), DATEPART(mm, cs.Data_lunii)), 2) AS luna, CONVERT(varchar(4), cs.an) AS an,
		RTRIM(s.lm_sup) AS loc_de_munca, RTRIM(c.tip_comanda) AS tip_comanda, RTRIM(s.comanda_sup) AS comanda, 
		MAX(RTRIM(c.descriere)) AS denumire, CONVERT(decimal(15,3), SUM(s.cantitate * s.valoare)) AS cheltuieli_totale,
		RTRIM(a.articol_de_calculatie) AS articol, MAX(RTRIM(a.denumire)) AS denArt,
		MAX(a.ordinea_in_raport) AS ordinea_in_raport, MAX(RTRIM(cs.LunaAlfa)) AS denluna,
		ISNULL(MAX(costuriSQL.cantitate), 0) AS cantitate, MAX(RTRIM(n.Denumire)) AS denProdus,
		pozcom.Cod_produs
	INTO #date
	FROM costsql s
	INNER JOIN calstd cs ON cs.data = s.data
	LEFT JOIN comenzi c ON c.Subunitate = @subunitate AND s.comanda_sup = c.comanda
	LEFT JOIN pozcom ON pozcom.subunitate = 'GR' AND s.comanda_sup = pozcom.comanda
	LEFT JOIN nomencl n ON n.cod = pozcom.Cod_produs
	INNER JOIN artcalc a ON (CASE WHEN s.art_inf = 'T' THEN s.art_sup ELSE s.art_inf END) = a.articol_de_calculatie
	LEFT JOIN costurisql ON costurisql.Data = s.Data AND costuriSQL.lm = s.LM_SUP AND costuriSQL.comanda = s.COMANDA_SUP
	LEFT JOIN lm ON lm.Cod = s.LM_SUP
	WHERE (@lm IS NULL OR s.lm_sup LIKE RTRIM(@lm) + '%')
		AND s.data BETWEEN @datajos AND @datasus 
		AND (@TipComanda = 'N' OR c.tip_comanda = @TipComanda)
		AND (NULLIF(@artcalc, '') IS NULL OR a.articol_de_calculatie = @artcalc) 
		AND (@comanda IS NULL OR s.comanda_sup LIKE RTRIM(@comanda) + '%') AND ISNULL(s.COMANDA_SUP, '') <> ''
		AND (@produs IS NULL OR n.Denumire LIKE '%' + @produs + '%' OR pozcom.Cod_produs LIKE '%' + @produs + '%')
	GROUP BY cs.data_lunii, cs.An, s.lm_sup, s.comanda_sup, c.tip_comanda,
		a.articol_de_calculatie, pozcom.Cod_produs
	ORDER BY cs.data_lunii, cs.An, s.COMANDA_SUP, a.Articol_de_calculatie

	ALTER TABLE #date ADD total decimal(15,3), pret_unitar decimal(15,3), procent decimal(5,2)

	/** Cantitate pe articole/luna */
	UPDATE #date
	SET #date.cantitate = c.cantitate
	FROM (SELECT data, loc_de_munca, comanda, MAX(cantitate) AS cantitate FROM #date GROUP BY data, loc_de_munca, comanda) AS c
	WHERE c.data = #date.data AND c.loc_de_munca = #date.loc_de_munca AND c.comanda = #date.comanda

	/** Total cheltuieli pe articole/luna */
	UPDATE #date
	SET #date.total = t.total
	FROM (SELECT data, loc_de_munca, comanda, SUM(cheltuieli_totale) AS total FROM #date GROUP BY data, loc_de_munca, comanda) AS t
	WHERE t.data = #date.data AND t.loc_de_munca = #date.loc_de_munca AND t.comanda = #date.comanda

	/** Pret unitar pe articole/luna */
	UPDATE #date
	SET pret_unitar = (CASE WHEN cantitate = 0 THEN 0 ELSE cheltuieli_totale / cantitate END)

	--> Total / Cantitate = pretul unitar pe total
	UPDATE #date
	SET procent = (CASE WHEN cantitate = 0 THEN 0 ELSE (pret_unitar * 100)/(total / cantitate) END)

	/** Centralizam cantitatile distribuite pe articole/luna --> vom avea cantitati pe comanda/loc_munca si total (gruparile din raport) */
	SELECT MAX(cantitate) AS cantitate, datal, loc_de_munca, comanda, 0 AS cant_inf, 0 AS cant_sup,
		CONVERT(decimal(15,3), 0) AS cheltGrupare, CONVERT(decimal(15,3), 0) AS cheltTotal
	INTO #grupare
	FROM #date
	GROUP BY datal, loc_de_munca, comanda

	/** Cantitati pe gruparea inferioara (loc de munca sau comenzi) */
	UPDATE #grupare
	SET cant_inf = s.cantitate
	FROM (SELECT SUM(cantitate) AS cantitate, comanda, loc_de_munca FROM #grupare GROUP BY comanda, loc_de_munca) AS S
	WHERE s.comanda = #grupare.comanda AND s.loc_de_munca = #grupare.loc_de_munca

	/** Cantitatea totala (gruparea superioara) */
	UPDATE #grupare
	SET cant_sup = s.cantitate
	FROM (SELECT SUM(cantitate) AS cantitate, (CASE WHEN @grupare = 'C' THEN comanda ELSE loc_de_munca END) AS grup
		FROM #grupare GROUP BY (CASE WHEN @grupare = 'C' THEN comanda ELSE loc_de_munca END)) AS s
	WHERE (CASE WHEN @grupare = 'C' THEN #grupare.comanda ELSE #grupare.loc_de_munca END) = s.grup

	/** Cheltuieli totale pe loc de munca/comenzi (gruparea inferioara) */
	UPDATE #grupare
	SET cheltGrupare = s.cheltuieli
	FROM (SELECT SUM(cheltuieli_totale) as cheltuieli, comanda, loc_de_munca FROM #date GROUP BY comanda, loc_de_munca) AS s
	WHERE s.comanda = #grupare.comanda AND s.loc_de_munca = #grupare.loc_de_munca

	/** Cheltuieli totale pe gruparea superioara */
	UPDATE #grupare
	SET cheltTotal = s.cheltuieli
	FROM (SELECT SUM(cheltuieli_totale) AS cheltuieli, (CASE WHEN @grupare = 'C' THEN comanda ELSE loc_de_munca END) AS grup
		FROM #date GROUP BY (CASE WHEN @grupare = 'C' THEN comanda ELSE loc_de_munca END)) AS s
	WHERE (CASE WHEN @grupare = 'C' THEN #grupare.comanda ELSE #grupare.loc_de_munca END) = s.grup

	/** Select final */
	SELECT d.*, g.cant_inf AS cantGrupare, g.cant_sup AS cantTotala, g.cheltGrupare, g.cheltTotal,
		CONVERT(decimal(15,3), (CASE WHEN g.cant_inf = 0 THEN 0 ELSE g.cheltGrupare / g.cant_inf END)) AS pretUnitarGrupare,
		CONVERT(decimal(15,3), (CASE WHEN g.cant_sup = 0 THEN 0 ELSE g.cheltTotal / g.cant_sup END)) AS pretUnitarTotal
	FROM #date d
	LEFT JOIN #grupare g ON g.datal = d.datal AND g.loc_de_munca = d.loc_de_munca AND g.comanda = d.comanda

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
