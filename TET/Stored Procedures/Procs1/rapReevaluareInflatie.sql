
/** Procedura pentru raportul MF: Reevaluare inflatie */

CREATE PROCEDURE rapReevaluareInflatie @sesiune varchar(50), @data_lunii datetime, @lm varchar(20), @cont varchar(20), @indice float
AS
BEGIN
	DECLARE @utilizator varchar(50)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	IF ISNULL(@indice, 0) = 0
		RAISERROR('Completati indicele de inflatie!', 16, 1)

	SET @data_lunii = dbo.EOM(@data_lunii)

	SELECT ROW_NUMBER() OVER (ORDER BY f.Cont_mijloc_fix, m.Numar_de_inventar) AS nrcrt,
		RTRIM(m.Denumire) AS denumire, RTRIM(m.Numar_de_inventar) AS nr_inventar, RTRIM(m.Cod_de_clasificare) AS cod_clasificare,
		CONVERT(varchar(10), m.Data_punerii_in_functiune, 103) AS data_intrarii, CONVERT(varchar(10), @data_lunii, 103) AS data_lunii,
		CONVERT(decimal(15,2), f.Valoare_de_inventar) AS val_inregistrare, m.Data_punerii_in_functiune AS data_intrarii_d,
		f.Durata * 12 AS durata_catalog,
		(f.Durata * 12) - f.Numar_de_luni_pana_la_am_int AS durata_consumata,
		f.Numar_de_luni_pana_la_am_int AS durata_ramasa,
		CONVERT(decimal(17,5), 0) AS grad_utilizare,
		CONVERT(decimal(15,2), 0) AS val_consumata,
		CONVERT(decimal(15,2), 0) AS val_ramasa,
		CONVERT(decimal(15,2), 0) AS val_actualizata,
		CONVERT(decimal(15,2), 0) AS dif_inregistrare,
		CONVERT(decimal(15,2), 0) AS dif_consumata,
		CONVERT(decimal(15,2), 0) AS dif_ramasa,
		CONVERT(decimal(15,2), 0) AS val_de_amortizat,
		CONVERT(varchar(50), '') AS observatii, RTRIM(f.Cont_mijloc_fix) AS cont, RTRIM(c.Denumire_cont) AS dencont,
		RTRIM(f.Loc_de_munca) AS lm, RTRIM(lm.Denumire) AS denlm, CONVERT(decimal(15,2), f.Valoare_amortizata) AS val_amortizata
	INTO #reevaluari
	FROM MFix m
	INNER JOIN fisaMF f ON f.Subunitate = m.Subunitate AND f.Numar_de_inventar = m.Numar_de_inventar
	LEFT JOIN conturi c ON c.Cont = f.Cont_mijloc_fix
	LEFT JOIN lm ON lm.Cod = f.Loc_de_munca
	WHERE f.Data_lunii_operatiei = @data_lunii
		AND (@lm IS NULL OR f.Loc_de_munca LIKE @lm + '%')
		AND (@cont IS NULL OR f.Cont_mijloc_fix LIKE @cont + '%')
		AND f.Felul_operatiei = '1'
	
	/** Calculare durata ramasa pana la amortizare, grad de utilizare si valoare actualizata cu indicele de inflatie */
	UPDATE i
	SET i.grad_utilizare = CONVERT(decimal(17,5), (CASE WHEN ISNULL(i.val_inregistrare, 0) = 0 THEN 0
			ELSE i.val_amortizata / i.val_inregistrare END)),
		i.val_actualizata = CONVERT(decimal(15,2), i.val_inregistrare * @indice)
	FROM #reevaluari i

	/** Calculare valoare aferenta duratei normale de functionare consumata si diferenta de inregistrat in contabilitate */
	UPDATE i
	SET i.val_consumata = i.val_amortizata,
		i.dif_inregistrare = i.val_actualizata - i.val_inregistrare	
	FROM #reevaluari i

	UPDATE i
	SET i.val_ramasa = i.val_inregistrare - i.val_consumata,
		i.dif_consumata = i.dif_inregistrare * i.grad_utilizare
	FROM #reevaluari i

	UPDATE i
	SET i.dif_ramasa = i.dif_inregistrare - i.dif_consumata
	FROM #reevaluari i

	/** Calculare valoare de amortizat si scriere grad de utilizare ca procentaj. */
	UPDATE i
	SET i.val_de_amortizat = i.val_ramasa + i.dif_ramasa,
		i.grad_utilizare = i.grad_utilizare * 100
	FROM #reevaluari i

	/** Nu se reevalueaza mijloacele fixe intrate in anul curent */
	UPDATE r
	SET r.observatii = 'fara reevaluare',
		r.dif_consumata = 0, r.dif_inregistrare = 0, r.dif_ramasa = 0,
		r.val_de_amortizat = 0, r.val_actualizata = 0
	FROM #reevaluari r
	WHERE YEAR(r.data_intrarii_d) = YEAR(@data_lunii)
		AND r.val_inregistrare <> r.val_amortizata

	/** Nu mai afisam unele date pentru mijloacele fixe care s-au amortizat integral */
	UPDATE r
	SET r.durata_consumata = r.durata_catalog, r.durata_ramasa = 0,
		r.val_ramasa = 0, r.dif_consumata = 0, r.dif_inregistrare = 0,
		r.dif_ramasa = 0, r.val_de_amortizat = 0, r.val_actualizata = 0,
		r.observatii = 'am. integral'
	FROM #reevaluari r
	WHERE r.val_inregistrare = r.val_amortizata

	SELECT * FROM #reevaluari
	ORDER BY cont, nr_inventar

END
