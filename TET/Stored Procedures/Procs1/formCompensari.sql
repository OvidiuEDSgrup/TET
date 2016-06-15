/**
	Formularul este folosit pentru a lista Compensari. 

**/
CREATE PROCEDURE formCompensari @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS
begin try 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @firma VARCHAR(100), @adr VARCHAR(100), @cui VARCHAR(100), @ordreg VARCHAR(100), @jud VARCHAR(100), @loc varchar(100), @cont VARCHAR(100), 
		@banca varchar(100), @tip varchar(2), @numar varchar(20),
		@mesaj varchar(1000), @subunitate varchar(10), @data datetime, @cTextSelect nvarchar(max), @debug bit, 
		@gestiune varchar(20), @utilizator varchar(50)
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	/** Filtre **/
	SET @tip=@parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @numar=@parXML.value('(/*/@numar)[1]', 'varchar(20)')
	SET @data= @parXML.value('(/*/@data)[1]', 'datetime')
			
	/* Alte **/
	
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	IF OBJECT_ID('tempdb..#pozadocFiltr') IS NOT NULL
		DROP TABLE #pozadocFiltr

	/** Pragatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre**/
	CREATE TABLE [dbo].[#pozadocFiltr] ([Numar_document] [varchar](20) NOT NULL,[Data] [datetime] NOT NULL,[Tert] [varchar](13) NOT NULL,
		[Tip] [varchar](2) NOT NULL,[Factura_stinga] [varchar](20) NOT NULL,[Factura_dreapta] [varchar](20) NOT NULL,[Cont_deb] [varchar](40) NOT NULL,
		[Cont_cred] [varchar](40) NOT NULL,[Suma] [float] NOT NULL,[TVA11] [float] NOT NULL,[TVA22] [float] NOT NULL,[Utilizator] [varchar](10) NOT NULL,
		[Data_operarii] [datetime] NOT NULL,[Ora_operarii] [varchar](6) NOT NULL,[Numar_pozitie] [int] NOT NULL,[Tert_beneficiar] [varchar](13) NOT NULL,
		[Explicatii] [varchar](50) NOT NULL,[Valuta] [varchar](3) NOT NULL,[Curs] [float] NOT NULL,[Suma_valuta] [float] NOT NULL,
		[Cont_dif] [varchar](40) NOT NULL,[suma_dif] [float] NOT NULL,[Loc_munca] [varchar](9) NOT NULL,[Comanda] [varchar](40) NOT NULL,
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
		and pz.numar_document = @numar
	
	
	/**
		Informatiile din PAR sau similare se iau o singura data, nu in selectul principal care ar cauza rularea instructiunilor de multe ori
	*/
	SELECT @firma = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'NUME'
	SELECT @cui = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CODFISC'
	select @jud= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'JUDET'
	select @loc= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'SEDIU'
			
	/** Selectul principal	**/
	SELECT
	@firma as UNITATE, @cui as CIF, @jud as JUDET, @loc as SEDIU, 
	rtrim(t.denumire) as DENUMIRE,
	rtrim(t.cod_fiscal) as CUI,
	rtrim(t.localitate) as LOCALITATE,
	convert(CHAR(10),pz.data,103) as DATAD,
	rtrim(pz.numar_document) as NRDOC,
	pz.tert+' '+t.denumire as TERT,
	rtrim(pz.factura_stinga) as FSTG,
	rtrim(pz.factura_dreapta) as FDR,
	convert(char(10),pz.data_fact,103) as DATAF,
	rtrim(pz.cont_deb) as CONTDB,
	rtrim(pz.cont_cred) as CONTCD,
	substring(convert(char(17),convert(money,round(pz.suma,2)),1),4,14) AS SUMA,
	substring(convert(char(17),convert(money,round((select sum(suma) from #pozadocFiltr),2)),1),4,14) as SSUMA


	into #selectMare
	FROM 
	#pozadocFiltr pz
	LEFT JOIN terti t on t.Tert=pz.Tert and t.Subunitate=@Subunitate
		
	ORDER BY pz.data, pz.numar_document

	SET @cTextSelect = '
	SELECT *
	into ' + @numeTabelTemp + '
	from #selectMare
	ORDER BY DATAD
	'

	EXEC sp_executesql @statement = @cTextSelect

	/** 
		Daca sunt lucruri specifice de tratat ele vor fi evidentiate in procedura formReceptiiSP1
		prin interventie asupra tabelului @numeTabelTemp (fie alterari ale datelor, fie coloane noi, samd )
	**/
	if exists (select 1 from sysobjects where type='P' and name='formCompensariSP1')
	begin
		exec formCompensariSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
	end

	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'select * from ' + @numeTabelTemp

		EXEC sp_executesql @statement = @cTextSelect
	END
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (formCompensari)'
	raiserror(@mesaj, 11, 1)
end catch
