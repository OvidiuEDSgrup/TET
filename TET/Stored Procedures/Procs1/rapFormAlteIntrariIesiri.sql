/**
	Formular PDF folosit pentru a lista Alte iesiri din macheta Intrari/Iesiri -> Alte iesiri. 
		@sesiune - sesiune utilizator
		@tip - tip document (AI, AE)
		@numar - numarul intrarii/iesirii
		@data - data intrarii/iesirii

**/

CREATE PROCEDURE rapFormAlteIntrariIesiri @sesiune varchar(50), @tip varchar(2), @numar varchar(20), @data datetime
AS
BEGIN TRY 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @utilizator varchar(20), @subunitate varchar(20), @detalii xml, @locm varchar(50)
	
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	
	IF OBJECT_ID('tempdb..#PozDocFiltr') IS NOT NULL
		DROP TABLE #PozDocFiltr
			
	/** Pragatire prefiltrare din tabela pz pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre */
	CREATE TABLE #PozDocFiltr ([Numar] [varchar](20) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Pret_valuta] [float] NOT NULL, [Pret_de_stoc] [float] NOT NULL, 
		[Adaos] [real] NOT NULL, [Pret_vanzare] [float] NOT NULL, [Pret_cu_amanuntul] [float] NOT NULL, [TVA_deductibil] [float] NOT NULL, 
		[Cota_TVA] [real] NOT NULL, [Cod_intrare] [varchar](13) NOT NULL,
		[Loc_de_munca] [varchar](9) NOT NULL, [Comanda] [varchar](40) NOT NULL, [Tert] [varchar](13) NOT NULL,
		[Numar_pozitie] [int], [Utilizator] [varchar](200)
		)

	INSERT INTO #PozDocFiltr (
		Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, 
		TVA_deductibil, Cota_TVA, Cod_intrare, Loc_de_munca, Comanda, Tert, Numar_pozitie, Utilizator
		)
	SELECT
		RTRIM(Numar), RTRIM(Cod), Data, RTRIM(Gestiune), Cantitate, Pret_valuta, Pret_de_stoc, 
		Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, RTRIM(Cod_intrare), 
		Loc_de_munca, RTRIM(Comanda), RTRIM(pz.Tert), Numar_pozitie, RTRIM(Utilizator)
	FROM pozdoc pz
	WHERE pz.subunitate = @subunitate
		AND pz.tip = @tip
		AND pz.data = @data
		AND pz.numar = @numar

	CREATE INDEX IX1 ON #PozDocFiltr(numar,data)
	CREATE INDEX IX2 ON #PozDocFiltr(cod)
	CREATE INDEX IX3 ON #PozDocFiltr(cantitate, pret_valuta)
	
	select top 1 @detalii = detalii, @locm = RTRIM(Loc_munca) FROM doc WHERE Tip = @tip AND numar = @numar AND data = @data

	/** Datele despre firma se vor stoca de acuma incolo in tabela #dateFirma */
	IF OBJECT_ID('tempdb.dbo.#dateFirma') IS NOT NULL DROP TABLE #dateFirma
	CREATE TABLE #dateFirma(locm varchar(50))
	exec wDateFirma_tabela
	EXEC wDateFirma @locm = @locm

	/** Selectul principal	**/
	SELECT 
		df.firma AS UNITATE, df.sediu AS LOCALITATE, df.codFiscal AS CUI, df.ordreg AS ORDREG, df.judet AS JUDET,
		CONVERT(varchar(10), pz.data, 103) AS DATA,
		RTRIM(pz.numar) AS NUMAR,
		RTRIM(g.Denumire_gestiune) AS GEST,
		RTRIM(lm.Denumire) AS LM,
		RTRIM(t.Denumire) AS DENTERT,
		ROW_NUMBER() OVER (ORDER BY pz.cod) AS nrcrt,
		RTRIM(pz.cod) AS cod,
		RTRIM(pz.Cod_intrare) AS codintrare,
		RTRIM(n.denumire) AS denumire,
		RTRIM(n.um) AS um,
		ROUND(pz.cantitate, 2) AS cantitate,
		ROUND(pz.pret_de_stoc, 2) AS pret,
		ROUND(pz.TVA_deductibil, 2) AS tva,
		ISNULL(@detalii.value('(/row/@observatii)[1]', 'varchar(300)'), '') AS OBSERVATII,
		'Operat: ' + rtrim (pz.utilizator) + '. Tiparit la ' + convert(varchar(10), getdate(), 103) + ' ' + convert(varchar(5), getdate(), 108)
			+ ', de catre ' + @utilizator as date_tiparire,
		pz.Numar_pozitie AS ordine
	INTO #date
	FROM #PozDocFiltr pz
	LEFT JOIN nomencl n ON n.Cod = pz.Cod
	LEFT JOIN gestiuni g ON g.Subunitate = @subunitate AND pz.gestiune = g.cod_gestiune
	LEFT JOIN lm ON pz.Loc_de_munca = lm.Cod
	LEFT JOIN terti t ON t.Subunitate = @subunitate AND t.Tert = pz.Tert
	LEFT JOIN #dateFirma df ON 1 = 1
	
	/** Posibilitate specifice */
	IF EXISTS (SELECT 1 FROM sys.sysobjects WHERE name = 'rapFormAlteIntrariIesiriSP')
		EXEC rapFormAlteIntrariIesiriSP @sesiune = @sesiune, @tip = @tip, @numar = @numar, @data = @data

	SELECT * FROM #date ORDER BY ordine

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
