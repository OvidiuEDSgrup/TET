CREATE PROCEDURE rapStructuraCastiguriSalarialePS @sesiune varchar(50)=null, @luna varchar(2), @anul varchar(4), @marca varchar(50)=null, @locmunca varchar(50)=null
AS
/**
	exec rapStructuraCastiguriSalarialePS '', '10', '2014', '1609', null
*/
BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @utilizator varchar(50), @data datetime, @dataString varchar(20), @dataAnJos datetime, @dataAnSus datetime, @oreLuna float, @ScadOS_RN int, @ScadO100_RN int
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	/** Validare an si creare data */
	IF LEN(@anul) <> 4 OR @anul LIKE '%[a-z]%'
		RAISERROR('Anul trebuie sa fie din 4 cifre!', 16, 1)

	SET @dataString = @anul + '-' + @luna + '-01'
	SET @data = CONVERT(datetime, @dataString)
	SET @data = dbo.EOM(@data)
	SET @oreLuna = dbo.iauParLN (@data,'PS','ORE_LUNA')

	SELECT
		@ScadOS_RN=max(case when parametru='OSNRN' then Val_logica else 0 end),
		@ScadO100_RN=max(case when parametru='O100NRN' then Val_logica else 0 end)
	from par where tip_parametru in ('PS') and parametru in ('OSNRN','O100NRN')
	
	/** Setam data inferioara pentru un an intreg */
	--SELECT @dataAnJos = dbo.eom(DATEADD(MONTH, 1, DATEADD(year, -1, @data)))
	SELECT @dataAnJos = dbo.BOY(@data)	--Pare ca se doreste urmarirea pentru anul selectat (si nu pentru ultimele 12 luni).
	SELECT @dataAnSus = dbo.EOY(@data)	--Pare ca se doreste urmarirea pentru anul selectat (si nu pentru ultimele 12 luni).

	IF OBJECT_ID('tempdb.dbo.#dateSalariat') IS NOT NULL DROP TABLE #dateSalariat
	IF OBJECT_ID('tempdb.dbo.#sumeLuna') IS NOT NULL DROP TABLE #sumeLuna
	IF OBJECT_ID('tempdb.dbo.#sumeAn') IS NOT NULL DROP TABLE #sumeAn
	IF OBJECT_ID('tempdb.dbo.#personal') IS NOT NULL DROP TABLE #personal
	IF OBJECT_ID('tempdb.dbo.#conmed') IS NOT NULL DROP TABLE #conmed
	IF OBJECT_ID('tempdb.dbo.#concodih') IS NOT NULL DROP TABLE #concodih
	IF OBJECT_ID('tempdb.dbo.#conalte') IS NOT NULL DROP TABLE #conalte
	IF OBJECT_ID('tempdb.dbo.#brut') IS NOT NULL DROP TABLE #brut

	CREATE TABLE #dateSalariat (nr_crt bigint, marca varchar(50), sex int, anul_nasterii int,
		loc_munca varchar(20), cetatenie int, data_incepere_activitate varchar(10), luna_incetare_activitate varchar(2),
		perioada_intrerupere_nrluni int, tip_contract_munca varchar(1), fel_contract_munca varchar(1),
		procent_din_timp_complet float, denfunctie varchar(200), cod_cor08 varchar(50), functie_in_conducere int,
		nivel_educatie varchar(100), codnivel_educatie varchar(50)
	)

	CREATE TABLE #sumeLuna (marca varchar(50), ore_lucru_lunar int, perioada_plata int, nrtotal_ore_platite int,
		nrtotal_ore_platite_supl int, salariu_brut float, sume_brute_platite float, sume_brute_ore_supl float,
		sume_schimb_noapte_zilelibere float, premii_ocazionale float, ajutoare_banesti float, sume_din_profitnet float,
		sume_din_alte_fonduri float, sume_buget_fond_national float, contributie_somaj float, contributie_asigsociale float,
		contributie_asigsanatate float, total_sume_brute float, impozit_sume_brute float
	)

	CREATE TABLE #sumeAn (marca varchar(50), sume_brute_platiteAN float, premii_ocazionaleAN float,
		ajutoare_banestiAN float, sume_din_profitnetAN float, sume_din_alte_fonduriAN float,
		sume_buget_fond_nationalAN float, nr_saptamaniAN int, nr_zileCO_platiteAN int, nr_zileBoala_platiteAN int,
		nr_zileBoala_platite_angajatorAN int, nr_zile_libereAN int, nr_zile_pregatire_profesionalaAN int
	)

	/*	Punem intr-o tabela temporara datele din tabela personal pentru a face filtrarea intr-un singur loc.	*/
	SELECT * INTO #personal
	FROM personal p
	LEFT JOIN LMFiltrare lu ON lu.utilizator=@utilizator AND lu.cod=p.Loc_de_munca
	where (ISNULL(@marca, '') = '' OR p.Marca = @marca)
		AND (ISNULL(@locmunca, '') = '' OR p.Loc_de_munca LIKE @locmunca + '%')
		AND (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)

	/* Calcul zile lucratoare platite de concediu medical.	*/
	SELECT cm.data, cm.marca, sum(cm.Zile_lucratoare) as zile_cm, sum(cm.Zile_cu_reducere) as zile_cm_unitate
	into #conmed
	FROM conmed cm
	INNER JOIN #personal p ON p.marca=cm.marca
	WHERE data BETWEEN @dataAnJos AND @dataAnSus and cm.Tip_diagnostic<>'0-'
	GROUP BY cm.data, cm.marca

	/* Calcul zile lucratoare platite de concediu de odihna.	*/
	SELECT co.data, co.marca, sum(co.Zile_CO) as zile_co
	into #concodih
	FROM concodih co
	INNER JOIN #personal p ON p.marca=co.marca
	WHERE co.data BETWEEN @dataAnJos AND @dataAnSus and co.tip_concediu in ('1','3','4','6','7','8')
	GROUP BY co.data, co.marca

	/* Calcul zile lucratoare pentru formare profesionala.	*/
	SELECT ca.data, ca.marca, sum(ca.Zile) as zile_formare
	into #conalte
	FROM conalte ca
	INNER JOIN #personal p ON p.marca=ca.marca
	WHERE ca.data BETWEEN @dataAnJos AND @dataAnSus and ca.tip_concediu='F'
	GROUP BY ca.data, ca.marca
	
	/*	Calcul tichete de masa acordate (impozitate) in perioada. */
	IF OBJECT_ID('tempdb..#perTich') IS NOT NULL DROP TABLE #perTich
	IF OBJECT_ID('tempdb..#tichete') IS NOT NULL DROP TABLE #tichete
	
	CREATE TABLE #perTich (datalunii datetime, datajos datetime, datasus datetime)
	INSERT INTO #perTich
	SELECT data_lunii, dbo.iauParLD(fc.data_lunii,'PS','DJIMPZTIC'), dbo.iauParLD(fc.data_lunii,'PS','DSIMPZTIC')
	FROM fCalendar (@dataAnJos, @dataAnSus) fc where data=data_lunii
	CREATE TABLE #tichete 
		(marca varchar(6), data_salar datetime, data datetime, numar_tichete int, valoare_tichete float)
	DECLARE @datalunii datetime, @dataImpozJos datetime, @dataImpozSus datetime
	DECLARE tmpTich cursor for
	SELECT datalunii, datajos, datasus
	FROM #perTich

	OPEN tmpTich
	FETCH NEXT FROM tmpTich into @Datalunii, @dataImpozJos, @dataImpozSus
	WHILE @@fetch_status = 0 
	BEGIN
		INSERT INTO #tichete (marca, data_salar, data, numar_tichete, valoare_tichete)
		SELECT marca, @Datalunii, data, numar_tichete, valoare_tichete from dbo.fNC_tichete (@dataImpozJos, @dataImpozSus, isnull(@marca,''),1)
		FETCH NEXT FROM tmpTich INTO @Datalunii, @dataImpozJos, @dataImpozSus
	END

	/* Calcul sume din brut grupat pe data si marca.	*/
	SELECT b.data, b.marca, 		
		SUM(b.Ore_lucrate_regim_normal) AS Ore_lucrate_regim_normal,
		SUM(b.Ore_lucrate_regim_normal + b.Ore_suplimentare_1 + b.Ore_suplimentare_2 + b.Ore_suplimentare_3 + b.Ore_suplimentare_4 + b.Ore_spor_100 
			+ b.Ore_concediu_de_odihna + b.Ore_obligatii_cetatenesti + ISNULL(cm.zile_cm_unitate*(case when b.Spor_cond_10=0 then 8 else b.Spor_cond_10 end),0)) AS Total_ore_lucrate,
		SUM(b.Ore_lucrate_regim_normal + b.Ore_concediu_de_odihna + b.Ore_obligatii_cetatenesti 
			+ ISNULL(cm.zile_cm_unitate*(case when b.Spor_cond_10=0 then 8 else b.Spor_cond_10 end),0)
			+ ISNULL(cm.zile_cm-cm.zile_cm_unitate*(case when b.Spor_cond_10=0 then 8 else b.Spor_cond_10 end),0))
			*MAX((8.00/(case when b.Spor_cond_10=0 then 8.00 else b.Spor_cond_10 end))) AS ore_platite_rn,
		SUM(b.Ore_suplimentare_1 + b.Ore_suplimentare_2 + b.Ore_suplimentare_3 + b.Ore_suplimentare_4 + b.Ore_spor_100) AS ore_platite_supl,
		SUM(b.Venit_total - (b.Ind_c_medical_CAS + b.Spor_cond_9)) AS sume_brute_platite, --> B19
		SUM(b.Indemnizatie_ore_supl_1 + b.Indemnizatie_ore_supl_2 + b.Indemnizatie_ore_supl_3 + b.Indemnizatie_ore_supl_4 + b.Indemnizatie_ore_spor_100) AS ind_ore_platite_supl,
		SUM(b.Ind_ore_de_noapte) AS Ind_ore_de_noapte,
		SUM(b.Premiu) AS premiu,
		/*	Campurile de mai jos le-am pus pentru a putea trata in proceduri specifice diverse cumulari ale acestor sume la coloana Premii sau la alte fonduri. */
		SUM(b.Diurna) AS Diurna, SUM(b.Cons_admin) AS Cons_admin, SUM(b.Suma_impozabila) AS Suma_impozabila, SUM(b.CO) AS CO, SUM(b.Restituiri) AS Restituiri,
		SUM(b.Suma_imp_separat) AS Suma_imp_separat, SUM(b.Sp_salar_realizat) AS Sp_salar_realizat, 
		SUM(b.Ind_c_medical_CAS+b.Spor_cond_9+b.Compensatie) as Sume_FNUASS,
		SUM(b.Ore_obligatii_cetatenesti/(case when b.Spor_cond_10=0 then 8 else b.Spor_cond_10 end)) as Zile_CO_eveniment,
		SUM(b.Ore_concediu_de_odihna/(case when b.Spor_cond_10=0 then 8 else b.Spor_cond_10 end)) as Zile_CO
	into #brut
	FROM brut b
	INNER JOIN #personal p ON p.marca=b.marca
	LEFT OUTER JOIN #conmed cm ON cm.Marca=b.Marca and cm.Data=b.Data
	WHERE b.data BETWEEN @dataAnJos AND @dataAnSus
	GROUP BY b.data, b.marca

	/** Impartim datele pe 3 categorii: 
			1. Date despre salariati
			2. Timp de lucru si sume brute aferente lunii selectate
			3. Timp de lucru si sume brute aferente anului pana la luna selectata
		*/

	/** 1. Date despre salariati */
	INSERT INTO #dateSalariat (nr_crt, marca, sex, anul_nasterii, loc_munca, cetatenie, data_incepere_activitate,
		luna_incetare_activitate, perioada_intrerupere_nrluni, tip_contract_munca, fel_contract_munca,
		procent_din_timp_complet, denfunctie, cod_cor08, functie_in_conducere, nivel_educatie, codnivel_educatie
	)
	SELECT ROW_NUMBER() OVER (ORDER BY p.Marca) AS nr_crt,
		RTRIM(p.Marca) AS marca, CONVERT(int, p.Sex) AS sex,
		DATEPART(yyyy, p.Data_nasterii) AS anul_nasterii,
		/*RTRIM(p.Loc_de_munca)*/'' AS loc_munca,
		1 AS cetatenie, --> 1 = cetatenie romana, 2 = rezident cu cetatenie straina, 3 = navetist transfrontalier
		CONVERT(varchar(50), CONVERT(varchar(4), DATEPART(yyyy, p.Data_angajarii_in_unitate)) + ' - '
			+ RIGHT('0' + CONVERT(varchar(2), DATEPART(mm, p.Data_angajarii_in_unitate)), 2)) AS data_incepere_activitate,
		--> se trece luna incetarii activitatii daca este ulterioara sau in cursul lunii selectate si in cadrul anului selectat.
		(CASE WHEN ((p.Data_plec < p.Data_angajarii_in_unitate) OR
			((DATEPART(mm, p.Data_plec) < DATEPART(mm, p.Data_angajarii_in_unitate) AND DATEPART(yyyy, p.Data_plec) = @anul) OR DATEPART(yyyy, p.Data_plec) <> @anul))
			THEN '' ELSE RIGHT('0' + CONVERT(varchar(2), DATEPART(mm, p.Data_plec)), 2) END) AS luna_incetare_activitate,
		0 AS perioada_intrerupere_nrluni,
		(CASE p.Mod_angajare WHEN 'N' THEN 1 WHEN 'D' THEN 2 ELSE 3 END) AS tip_contract_munca,
		(CASE WHEN p.salar_lunar_de_baza >= 8 THEN 1 ELSE 2 END) AS fel_contract_munca, --> 1 = timp complet, 2 = timp partial
		(CASE WHEN p.Salar_lunar_de_baza >= 8 THEN 100 ELSE (p.Salar_lunar_de_baza * 100)/8 END) AS procent_din_timp_complet, --> 8 ore = norma intreaga
		RTRIM(f.Denumire) AS denfunctie,
		LEFT(RTRIM(cc.Val_inf),4) AS cod_cor08,
		(CASE WHEN LEFT(cc.Val_inf, 1) = '1' THEN 1 ELSE 2 END) AS functie_in_conducere,
		'' AS nivel_educatie, '' AS codnivel_educatie --> vor fi completate..
	FROM #personal p
	INNER JOIN functii f ON f.Cod_functie = p.Cod_functie
	LEFT JOIN extinfop cc ON cc.Cod_inf = '#CODCOR' AND cc.Marca = f.Cod_functie
	LEFT JOIN extinfop cet ON cet.marca = p.marca AND cet.Cod_inf = 'RCETATENIE' AND cet.Data_inf = '01/01/1901'
	LEFT JOIN CatalogRevisal cetrev ON cetrev.TipCatalog = 'Cetatenie' AND cetrev.Cod = cet.Val_inf
	
	/** 2. Timp de lucru si sume brute aferente lunii selectate */
	INSERT INTO #sumeLuna (marca, ore_lucru_lunar, perioada_plata, nrtotal_ore_platite, nrtotal_ore_platite_supl,
		salariu_brut, sume_brute_platite, sume_brute_ore_supl, sume_schimb_noapte_zilelibere, premii_ocazionale, ajutoare_banesti,
		sume_din_profitnet, sume_din_alte_fonduri, sume_buget_fond_national, contributie_somaj, contributie_asigsociale, contributie_asigsanatate,
		total_sume_brute, impozit_sume_brute
	)
	SELECT RTRIM(p.Marca) AS marca,
		ISNULL(@oreLuna/8*(case when max(i.Salar_lunar_de_baza)=0 then 8 else max(i.Salar_lunar_de_baza) end),0) AS ore_lucru_lunar,
		4 AS perioada_plata, --> 1 = 1 sapt., 2 = 2 sapt., 3 = 3 sapt., 4 = o luna
		SUM(ISNULL(b.Total_ore_lucrate, 0)) AS nrtotal_ore_platite,
		SUM(ISNULL(b.ore_platite_supl, 0)) AS nrtotal_ore_platite_supl,
		SUM(ISNULL(i.Salar_de_incadrare, 0)) AS salariu_brut, --> folosim ISNULL pentru cazul in care nu s-a facut nicio plata in luna aleasa
		SUM(ISNULL(b.sume_brute_platite, 0)) AS sume_brute_platite, --> B19
		SUM(ISNULL(b.ind_ore_platite_supl, 0)) AS sume_brute_ore_supl,
		SUM(ISNULL(b.Ind_ore_de_noapte, 0)) AS sume_schimb_noapte_zilelibere,
		SUM(ISNULL(b.Premiu, 0)) AS premii_ocazionale,
		0 AS ajutoare_banesti, --> ?!
		0 AS sume_din_profitnet, --> B24
		ROUND(SUM(ISNULL(t.valoare_tichete,0)),0) AS sume_din_alte_fonduri, --> B25
		SUM(ISNULL(b.Sume_FNUASS,0)) AS sume_buget_fond_national, --> B26
		SUM(ISNULL(n.Somaj_1, 0)) AS contributie_somaj,
		SUM(ISNULL(n.Pensie_suplimentara_3, 0)) AS contributie_asigsociale,
		SUM(ISNULL(n.Asig_sanatate_din_net, 0)) AS contributie_asigsanatate,
		0 AS total_sume_brute, --> se calculeaza mai jos, in update
		SUM(ISNULL(n.Impozit, 0)) AS impozit_sume_brute	
	FROM #personal p
	LEFT JOIN #brut b ON b.Marca = p.Marca AND b.Data = @data
	LEFT JOIN net n ON n.Marca = p.Marca AND n.Data = @data
	LEFT JOIN istPers i ON i.Marca = p.Marca AND i.Data = @data
	LEFT JOIN #tichete t ON t.Marca = p.Marca AND t.Data = @data
	GROUP BY p.Marca

	--> (B19 + B24 + B25 + B26)
	UPDATE #sumeLuna
	SET total_sume_brute = sume_brute_platite + sume_din_profitnet + sume_din_alte_fonduri + sume_buget_fond_national

	/** 3. Timp de lucru si sume brute aferente anului pana la luna selectata */
	INSERT INTO #sumeAn (marca, sume_brute_platiteAN, premii_ocazionaleAN, ajutoare_banestiAN, sume_din_profitnetAN,
		sume_din_alte_fonduriAN, sume_buget_fond_nationalAN, nr_saptamaniAN, nr_zileCO_platiteAN,
		nr_zileBoala_platiteAN, nr_zileBoala_platite_angajatorAN, nr_zile_libereAN, nr_zile_pregatire_profesionalaAN
	)
	SELECT RTRIM(p.Marca) AS marca,
		--> aceleasi date ca in tabelul #sumeLuna, dar aferente intregului an
		ISNULL(SUM(b.sume_brute_platite), 0) AS sume_brute_platiteAN,
		SUM(ISNULL(b.Premiu, 0)) AS premii_ocazionaleAN,
		0 AS ajutoare_banestiAN, --> ?!
		0 AS sume_din_profitnetAN,
		ROUND(SUM(ISNULL(t.valoare_tichete,0)),0) AS sume_din_alte_fonduriAN,
		SUM(ISNULL(b.Sume_FNUASS,0)) AS sume_buget_fond_nationalAN,
		ROUND(SUM(ISNULL(b.ore_platite_rn,0))/40.00,2) AS nr_saptamaniAN,
		SUM(ISNULL(co.Zile_CO, ISNULL(b.Zile_CO, 0))) AS nr_zileCO_platiteAN,
		SUM(ISNULL(cm.Zile_cm,0)) AS nr_zileBoala_platiteAN,
		SUM(ISNULL(cm.zile_cm_unitate,0)) AS nr_zileBoala_platite_angajatorAN,
		SUM(ISNULL(b.Zile_CO_eveniment,0)) AS nr_zile_libereAN,
		SUM(ISNULL(ca.Zile_formare,0)) AS nr_zile_pregatire_profesionalaAN
	FROM #personal p
	LEFT JOIN #brut b ON b.Marca = p.Marca AND b.Data BETWEEN @dataAnJos AND @dataAnSus
	LEFT JOIN #conmed cm ON cm.Marca = p.Marca AND cm.Data = b.Data
	LEFT JOIN #concodih co ON co.Marca = p.Marca AND co.Data = b.Data
	LEFT JOIN #conalte ca ON ca.Marca = p.Marca AND ca.Data = b.Data
	LEFT JOIN #tichete t ON t.Marca = p.Marca AND t.Data = b.Data
	GROUP BY p.Marca

	IF EXISTS (SELECT 1 FROM sys.sysobjects WHERE name = 'rapStructuraCastiguriSalarialePSSP')
		exec rapStructuraCastiguriSalarialePSSP @sesiune=@sesiune, @luna=@luna, @anul=@anul, @marca=@marca, @locmunca=@locmunca
	
	/** Select final */
	SELECT ds.*, --> datele despre salariati

		sl.ore_lucru_lunar, sl.perioada_plata, sl.nrtotal_ore_platite, sl.nrtotal_ore_platite_supl,
		sl.salariu_brut, sl.sume_brute_platite, sl.sume_brute_ore_supl, sl.sume_schimb_noapte_zilelibere,
		sl.premii_ocazionale, sl.ajutoare_banesti, sl.sume_din_profitnet, sl.sume_din_alte_fonduri,
		sl.sume_buget_fond_national, sl.contributie_somaj, sl.contributie_asigsociale, sl.contributie_asigsanatate,
		sl.total_sume_brute, sl.impozit_sume_brute, --> sumele/totalurile pe luna

		sa.sume_brute_platiteAN, sa.premii_ocazionaleAN, sa.ajutoare_banestiAN, sa.sume_din_profitnetAN,
		sa.sume_din_alte_fonduriAN, sa.sume_buget_fond_nationalAN, sa.nr_saptamaniAN, sa.nr_zileCO_platiteAN,
		sa.nr_zileBoala_platiteAN, sa.nr_zileBoala_platite_angajatorAN, sa.nr_zile_libereAN,
		sa.nr_zile_pregatire_profesionalaAN --> sumele/totalurile pe an pana la luna selectata
	FROM #dateSalariat ds
	INNER JOIN #sumeLuna sl ON sl.marca = ds.marca
	INNER JOIN #sumeAn sa ON sa.marca = ds.marca

	IF OBJECT_ID('tempdb.dbo.#dateSalariat') IS NOT NULL DROP TABLE #dateSalariat
	IF OBJECT_ID('tempdb.dbo.#sumeLuna') IS NOT NULL DROP TABLE #sumeLuna
	IF OBJECT_ID('tempdb.dbo.#sumeAn') IS NOT NULL DROP TABLE #sumeAn
	IF OBJECT_ID('tempdb.dbo.#personal') IS NOT NULL DROP TABLE #personal
	IF OBJECT_ID('tempdb.dbo.#conmed') IS NOT NULL DROP TABLE #conmed
	IF OBJECT_ID('tempdb.dbo.#concodih') IS NOT NULL DROP TABLE #concodih
	IF OBJECT_ID('tempdb.dbo.#conalte') IS NOT NULL DROP TABLE #conalte
	IF OBJECT_ID('tempdb.dbo.#brut') IS NOT NULL DROP TABLE #brut

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500), @errorSeverity int, @errorState int
		SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
		SET @errorSeverity = ERROR_SEVERITY()
		SET @errorState = ERROR_STATE()
	RAISERROR(@mesajEroare, @errorSeverity, @errorState)
END CATCH
