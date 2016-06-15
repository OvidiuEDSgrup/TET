
CREATE PROCEDURE rapFormCompensare @sesiune varchar(50), @parXML xml, @numeTabelTemp varchar(100) OUTPUT
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRY
	DECLARE @tip varchar(2), @numar varchar(20), @subunitate varchar(10), @data datetime,
		@cTextSelect nvarchar(max), @debug bit, @utilizator varchar(50), @locm varchar(50)
	
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	
	/** Date identificare document **/
	SET @tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @numar = @parXML.value('(/*/@numar)[1]', 'varchar(20)')
	SET @data = @parXML.value('(/*/@data)[1]', 'datetime')
			
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	IF OBJECT_ID('tempdb..#pozadocFiltr') IS NOT NULL
		DROP TABLE #pozadocFiltr

	/** Pregatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre */
	CREATE TABLE [dbo].[#pozadocFiltr] ([Numar_document] [varchar](20) NOT NULL,[Data] [datetime] NOT NULL,[Tert] [varchar](13) NOT NULL,
		[Tip] [varchar](2) NOT NULL,[Factura_stinga] [varchar](20) NOT NULL,[Factura_dreapta] [varchar](20) NOT NULL,[Cont_deb] [varchar](20) NOT NULL,
		[Cont_cred] [varchar](20) NOT NULL,[Suma] [float] NOT NULL,[TVA11] [float] NOT NULL,[TVA22] [float] NOT NULL,[Utilizator] [varchar](10) NOT NULL,
		[Data_operarii] [datetime] NOT NULL,[Ora_operarii] [varchar](6) NOT NULL,[Numar_pozitie] [int] NOT NULL,[Tert_beneficiar] [varchar](13) NOT NULL,
		[Explicatii] [varchar](50) NOT NULL,[Valuta] [varchar](3) NOT NULL,[Curs] [float] NOT NULL,[Suma_valuta] [float] NOT NULL,
		[Cont_dif] [varchar](20) NOT NULL,[suma_dif] [float] NOT NULL,[Loc_munca] [varchar](9) NOT NULL,[Comanda] [varchar](40) NOT NULL,
		[Data_fact] [datetime] NOT NULL,[Data_scad] [datetime] NOT NULL,[Stare] [smallint] NOT NULL,[Achit_fact] [float] NOT NULL,
		[Dif_TVA] [float] NOT NULL,[Jurnal] [varchar](3) NOT NULL)

	INSERT INTO #pozadocFiltr (
		Numar_document, Data, Tert, Tip, Factura_stinga, Factura_dreapta, Cont_deb, Cont_cred, Suma, TVA11, TVA22, Utilizator, Data_operarii, Ora_operarii, 
		Numar_pozitie, Tert_beneficiar, Explicatii, Valuta, Curs, Suma_valuta, Cont_dif, suma_dif, Loc_munca, Comanda, Data_fact, Data_scad, Stare, Achit_fact, 
		Dif_TVA, Jurnal
		)
		
	SELECT Numar_document, Data, Tert, Tip, Factura_stinga, Factura_dreapta, Cont_deb, Cont_cred, Suma, TVA11, TVA22, Utilizator, Data_operarii, Ora_operarii, 
		Numar_pozitie, Tert_beneficiar, Explicatii, Valuta, Curs, Suma_valuta, Cont_dif, suma_dif, Loc_munca, Comanda, Data_fact, Data_scad, Stare, Achit_fact, 
		Dif_TVA, Jurnal
	FROM pozadoc pz
	WHERE pz.subunitate = @subunitate
		AND pz.tip = @tip
		AND pz.data = @data
		AND pz.numar_document = @numar
	
	/** Total compensare */
	SELECT MAX(Numar_document) AS Numar_document, MAX(Data) AS data,
		MAX(Tip) AS tip, MAX(Tert) AS tert, SUM(Suma) AS total
	INTO #total
	FROM #pozadocFiltr

	SELECT TOP 1 @locm = RTRIM(Loc_munca) FROM doc WHERE Tip = @tip AND Numar = @numar AND Data = @data

	/** Datele despre firma se vor stoca de acuma incolo in tabela #dateFirma */
	IF OBJECT_ID('tempdb.dbo.#dateFirma') IS NOT NULL DROP TABLE #dateFirma
	CREATE TABLE #dateFirma(locm varchar(50))
	exec wDateFirma_tabela
	EXEC wDateFirma @locm = @locm

	/** Selectul principal	**/
	SELECT df.firma AS unitate, df.codFiscal AS cif, df.judet AS judet, df.sediu AS sediu,
		RTRIM(t.Tert) AS tert,
		RTRIM(t.denumire) AS dentert,
		RTRIM(t.cod_fiscal) AS cui,
		ISNULL(RTRIM(l.oras), RTRIM(t.localitate)) AS localitate,
		CONVERT(varchar(10), pz.data, 103) AS data,
		RTRIM(pz.numar_document) AS numar,
		RTRIM(pz.factura_stinga) AS factura_stanga,
		RTRIM(pz.factura_dreapta) AS factura_dreapta,
		CONVERT(varchar(10), ff.Data, 103) AS data_furnizor,
		CONVERT(varchar(10), fb.Data, 103) AS data_beneficiar,
		RTRIM(pz.cont_deb) AS cont_debitor,
		RTRIM(pz.cont_cred) AS cont_creditor,
		CONVERT(decimal(15,2), pz.suma) AS suma,
		RTRIM(u.Nume) AS operator,
		CONVERT(decimal(15,2), tot.total) AS total,
		'Operat: ' + RTRIM(pz.utilizator) + '. Tiparit la ' + CONVERT(varchar(10), GETDATE(), 103) + ' ' + CONVERT(varchar(5), GETDATE(), 108)
			+ ', de catre ' + u.Nume AS date_tiparire,
		pz.Numar_pozitie AS ordine
	INTO #selectMare
	FROM #pozadocFiltr pz
	INNER JOIN #total tot ON pz.Numar_document = tot.Numar_document AND pz.Data = tot.data AND pz.Tip = tot.tip AND pz.Tert = tot.tert
	LEFT JOIN facturi ff ON ff.Subunitate = @subunitate AND ff.Tip = 0x54 AND pz.Factura_stinga = ff.Factura AND pz.Tert = ff.Tert
	LEFT JOIN facturi fb ON fb.Subunitate = @subunitate AND fb.Tip = 0x46 AND pz.Factura_dreapta = fb.Factura AND pz.Tert = fb.Tert
	LEFT JOIN terti t ON t.Subunitate = @Subunitate AND t.Tert = pz.Tert
	LEFT JOIN utilizatori u ON u.ID = @utilizator
	LEFT JOIN Localitati l ON t.Localitate = l.cod_oras
	LEFT JOIN #dateFirma df ON 1 = 1

	/** Posibilitate specifice */
	IF EXISTS (SELECT 1 FROM sys.sysobjects WHERE name = 'rapFormCompensareSP')
		EXEC rapFormCompensareSP @sesiune = @sesiune, @parXML = @parXML

	SELECT * FROM #selectMare ORDER BY ordine
		
	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'SELECT * FROM ' + @numeTabelTemp
		EXEC sp_executesql @statement = @cTextSelect
	END

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
