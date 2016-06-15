/**
	Formularul PDF este folosit in machetele Intrari/Iesiri -> Predari ob.inv.
															-> Casari ob.inv.
															-> Alte intrari ob.inv.

**/
CREATE PROCEDURE rapFormFolosinte @sesiune varchar(50), @tip varchar(2), @numar varchar(20), @data datetime
AS
BEGIN TRY 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @subunitate varchar(10), @utilizator varchar(50), @locm varchar(50)
	
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	IF OBJECT_ID('tempdb..#PozDocFiltr') IS NOT NULL
		DROP TABLE #PozDocFiltr

	/** Pragatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre */
	CREATE TABLE #PozDocFiltr ([Numar] [varchar](20) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Pret_valuta] [float] NOT NULL, [Pret_de_stoc] [float] NOT NULL, 
		[Adaos] [real] NOT NULL, [Pret_vanzare] [float] NOT NULL, [Pret_cu_amanuntul] [float] NOT NULL, [TVA_deductibil] [float] NOT NULL, 
		[Cota_TVA] [real] NOT NULL, [Cod_intrare] [varchar](13) NOT NULL, [Locatie] [varchar](30) NOT NULL, [Data_expirarii] [datetime] NOT NULL, 
		[Loc_de_munca] [varchar](9) NOT NULL, [Comanda] [varchar](40) NOT NULL, [Barcod] [varchar](30) NOT NULL, 
		[Discount] [real] NOT NULL, [Tert] [varchar](13) NOT NULL, [Factura] [varchar](20) NOT NULL, 
		[Gestiune_primitoare] [varchar](20) NOT NULL, [Numar_DVI] [varchar](25) NOT NULL, [Valuta] [varchar](3) NOT NULL, [Curs] [float] NOT NULL, 
		[Data_facturii] [datetime] NOT NULL, [Data_scadentei] [datetime] NOT NULL, [Contract] [varchar](20) NOT NULL, [Utilizator] [varchar](200),
		[Numar_pozitie] [int]
		)

	INSERT INTO #PozDocFiltr (
		Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, 
		TVA_deductibil, Cota_TVA, Cod_intrare, Locatie, Data_expirarii, Loc_de_munca, Comanda, Barcod, Discount, Tert, 
		Factura, Gestiune_primitoare, Numar_DVI, Valuta, Curs, Data_facturii, Data_scadentei, Contract, Utilizator, Numar_pozitie
		)
	SELECT
		RTRIM(Numar), RTRIM(Cod), Data AS data, RTRIM(Gestiune), Cantitate, Pret_valuta, Pret_de_stoc, 
		Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, RTRIM(Cod_intrare), 
		RTRIM(Locatie), Data_expirarii, Loc_de_munca, RTRIM(Comanda), RTRIM(Barcod), 
		Discount, RTRIM(pz.Tert), RTRIM(Factura), RTRIM(Gestiune_primitoare), Numar_DVI, Valuta, 
		Curs, Data_facturii, Data_scadentei, RTRIM(Contract), RTRIM(Utilizator), Numar_pozitie
	FROM pozdoc pz
	WHERE pz.subunitate = @subunitate
		AND pz.tip = @tip
		AND pz.data = @data
		AND pz.numar = @numar

	CREATE INDEX IX1 ON #PozDocFiltr(numar, cod, cod_intrare)
	
	SELECT TOP 1 @locm = RTRIM(Loc_munca) FROM doc WHERE Tip = @tip AND Numar = @numar AND Data = @data

	/** Datele despre firma se vor stoca de acuma incolo in tabela #dateFirma */
	IF OBJECT_ID('tempdb.dbo.#dateFirma') IS NOT NULL DROP TABLE #dateFirma
	CREATE TABLE #dateFirma(locm varchar(50))
	exec wDateFirma_tabela
	EXEC wDateFirma @locm = @locm

	/** Selectul principal	**/
	SELECT
		df.firma AS UNITATE, df.codFiscal AS CUI, df.ordreg AS ORDREG, df.judet AS JUDET, df.sediu AS LOCALITATE,
		RTRIM(ISNULL(g.Denumire_gestiune, pp.Nume)) AS PRED,
		RTRIM(pz.numar) AS NUMAR,
		RTRIM(lm.Denumire) AS LM,
		CONVERT(varchar(10), pz.data, 103) AS DATA,
		RTRIM(ISNULL(p.Nume, '')) AS SALARIAT,
		ROW_NUMBER() OVER (ORDER BY pz.cod) AS nrcrt,
		RTRIM(pz.cod_intrare) as codintrare,
		RTRIM(pz.cod) AS cod,
		RTRIM(n.denumire) AS denumire,
		RTRIM(n.um) AS um,
		ROUND(pz.cantitate, 2) AS cantitate,
		ROUND(pz.pret_de_stoc, 2) AS pret,
		ROUND(pz.TVA_deductibil, 2) AS tva,
		'Operat: ' + rtrim (pz.utilizator) + '. Tiparit la ' + convert(varchar(10), getdate(), 103) + ' ' + convert(varchar(5), getdate(), 108)
			+ ', de catre ' + @utilizator as date_tiparire,
		pz.Numar_pozitie AS ordine
	INTO #date
	FROM #PozDocFiltr pz
	LEFT JOIN nomencl n ON n.Cod = pz.Cod
	LEFT JOIN gestiuni g ON g.Cod_gestiune = pz.Gestiune
	LEFT JOIN lm ON lm.Cod = pz.Loc_de_munca
	LEFT JOIN doc ON doc.Tip = @tip AND doc.Numar = pz.Numar AND doc.Data = pz.Data
	LEFT JOIN personal p ON p.marca = pz.Gestiune_primitoare
	LEFT JOIN personal pp ON pp.Marca = doc.Cod_gestiune
	LEFT JOIN #dateFirma df ON 1 = 1
	
	/** Posibilitate specifice */
	IF EXISTS (SELECT 1 FROM sys.sysobjects WHERE name = 'rapFormFolosinteSP')
		EXEC rapFormFolosinteSP @sesiune = @sesiune, @tip = @tip, @numar = @numar, @data = @data

	SELECT * FROM #date ORDER BY ordine

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
