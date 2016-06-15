/**
	Procedura este folosita pentru a lista Receptii si Receptii in pret cu amanuntul (fiecare are cate un sablon). 

**/
CREATE PROCEDURE formReceptii @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS
begin try 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @unitate VARCHAR(100), @tip varchar(2), @numar varchar(20),
		@mesaj varchar(1000), @subunitate varchar(10), @data datetime, @cTextSelect nvarchar(max), @debug bit, @cui VARCHAR(100), @ordreg VARCHAR(100), @jud VARCHAR(100), @loc varchar(100), 
		@cont VARCHAR(100), @banca varchar(100),@gestiune varchar(20), @factura varchar(20), @grupaTerti varchar(20), @utilizator varchar(50), @filtruFacturi bit
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	/** Filtre **/
	SET @tip=@parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @numar=@parXML.value('(/*/@numar)[1]', 'varchar(20)')
	SET @data= @parXML.value('(/*/@data)[1]', 'datetime')
	SET @gestiune= isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),'')
		
	/* Alte **/
	

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	IF OBJECT_ID('tempdb..#PozDocFiltr') IS NOT NULL
		DROP TABLE #PozDocFiltr

	/** Pragatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre**/
	CREATE TABLE [dbo].[#PozDocFiltr] ([Numar] [varchar](20) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Pret_valuta] [float] NOT NULL, [Pret_de_stoc] [float] NOT NULL, 
		[Adaos] [real] NOT NULL, [Pret_vanzare] [float] NOT NULL, [Pret_cu_amanuntul] [float] NOT NULL, [TVA_deductibil] [float] NOT NULL, 
		[Cota_TVA] [real] NOT NULL, [Cod_intrare] [varchar](13) NOT NULL, [TVA_neexigibil] [real] NOT NULL, [Locatie] [varchar](30) NOT NULL, [Data_expirarii] [datetime] NOT NULL, 
		[Loc_de_munca] [varchar](9) NOT NULL, [Comanda] [varchar](40) NOT NULL, [Barcod] [varchar](30) NOT NULL, 
		[Discount] [real] NOT NULL, [Tert] [varchar](13) NOT NULL, [Factura] [varchar](20) NOT NULL, 
		[Gestiune_primitoare] [varchar](13) NOT NULL, [Numar_DVI] [varchar](25) NOT NULL, [Valuta] [varchar](3) NOT NULL, [Curs] [float] NOT NULL, 
		[Data_facturii] [datetime] NOT NULL, [Data_scadentei] [datetime] NOT NULL, [Contract] [varchar](20) NOT NULL
		)

	INSERT INTO #PozDocFiltr (		
		Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, 
		TVA_deductibil, Cota_TVA, Cod_intrare, tva_neexigibil, Locatie, Data_expirarii, Loc_de_munca, Comanda, Barcod, Discount, Tert, 
		Factura, Gestiune_primitoare, Numar_DVI, Valuta, Curs, Data_facturii, Data_scadentei, Contract
		)
	SELECT rtrim(max(Numar)), rtrim(Cod), max(Data) data, max(rtrim(Gestiune)), sum(Cantitate), max(Pret_valuta), max(Pret_de_stoc), 
		MAX(Adaos), max(Pret_vanzare), max(Pret_cu_amanuntul), sum(TVA_deductibil), max(Cota_TVA), MAX(rtrim(Cod_intrare)), MAX(tva_neexigibil),
		MAX(rtrim(Locatie)), max(Data_expirarii), max(Loc_de_munca), max(rtrim(Comanda)), max(rtrim(Barcod)), 
		max(Discount), max(rtrim(pz.Tert)), rtrim(Factura), max(rtrim(Gestiune_primitoare)), max(Numar_DVI), max(Valuta), 
		max(Curs), Data_facturii, max(Data_scadentei), MAX(rtrim(Contract))
	FROM pozdoc pz
	
	WHERE pz.subunitate = @subunitate
		AND pz.tip = @tip
		AND pz.data = @data
		and pz.Numar = @numar
		AND (@gestiune = '' OR pz.Gestiune = @gestiune)
	group by pz.factura, pz.data_facturii, pz.cod
	

	create index IX1 on #pozdocfiltr(factura,data_facturii)
	create index IX2 on #pozdocfiltr(cod)
	create index IX3 on #pozdocfiltr(cantitate, pret_valuta)

	/**
		Informatiile din PAR sau similare se iau o singura data, nu in selectul principal care ar cauza rularea instructiunilor de multe ori
	*/
	SELECT @unitate = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'NUME'
	SELECT @cui = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CODFISC'
	SELECT @ordreg = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'ORDREG'
	select @cont=rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CONTBC'
	select @banca= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'BANCA'
	select @jud= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'JUDET'
	select @loc= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'SEDIU'
	
	/** Selectul principal	**/
	SELECT
	@unitate as UNITATE, @cui as CUI, @ordreg as ORDREG, @cont as CONT, @banca as BANCA, 
	convert(CHAR(10),pz.data,103) as DATA,
	ltrim(pz.numar) as DOC,
	row_number() OVER(ORDER BY pz.cod) as NR,
	rtrim(pz.cod) as COD,
	ltrim(rtrim(g.denumire_gestiune)) as GEST,
	rtrim(ltrim(t.denumire)) as FURN,
	rtrim(ltrim(pz.factura)) as FACT,
	rtrim(n.denumire) as DENUMIRE,
	n.um as UM,
	left(convert(char(18),convert(money,pz.pret_de_stoc),2),17) as PRET,
	substring(convert(char(18),convert(money,round(pz.cantitate,2)),2),6,12) as CANT,
	substring(convert(char(17),convert(money,round(pz.pret_de_stoc*pz.cantitate,2)),1),4,14) as VAL,
	convert(char(17),convert(money,round(pz.TVA_deductibil,2)),1) as TVA,
	convert(char(17),convert(money,round((select sum(p.pret_de_stoc*p.cantitate) from #PozDocFiltr p where p.data=pz.data and p.numar=pz.numar),2)),1) as TVAL,
	convert(char(17),convert(money,round((select sum(p.TVA_deductibil) from #PozDocFiltr p where p.numar=pz.numar and p.data=pz.data)
		+isnull((select sum(p.TVA_deductibil) from pozdoc p where p.subunitate=@subunitate and p.tip='RP' and p.numar=@numar and p.data=@data),0)+isnull((select sum(dvi.TVA_22) from dvi where dvi.subunitate=@subunitate and dvi.numar_receptie=@numar and dvi.data_receptiei=@data),0)
	,2)),1) as TTVA,
	convert(char(17),convert(money,round((select (sum(p.pret_de_stoc*p.cantitate)+sum(p.TVA_deductibil)) from #PozDocFiltr p where p.numar=pz.numar and p.data=pz.data)
		+isnull((select sum(p.TVA_deductibil) from pozdoc p where p.subunitate=@subunitate and p.tip='RP' and p.numar=@numar and p.data=@data),0)+isnull((select sum(dvi.TVA_22) from dvi where dvi.subunitate=@subunitate and dvi.numar_receptie=@numar and dvi.data_receptiei=@data),0)
	,2)),1) as TOTAL,
	a.numele_delegatului as MEMBR1,
	a.eliberat as MEMBR2,
	a.mijloc_de_transport AS MEMBR3,
	a.observatii as MEMBR4,
	-- pentru receptii in pret cu amanuntul
	left(convert(char(18),convert(money,round(n.pret_cu_amanuntul,2)),2),17) as PRETV,
	left(convert(char(18),convert(money,round(n.pret_cu_amanuntul*pz.cantitate,2)),2),17) as VALPV,
	substring(convert(char(17),convert(money,round(pz.cantitate*(pz.pret_cu_amanuntul/(1+convert(decimal(12,3),pz.tva_neexigibil)/100)-pz.pret_de_stoc),2)),1),4,14) as AD,
	substring(convert(char(17),convert(money,round(pz.pret_cu_amanuntul,2)),1),4,14) as PRAM,
	substring(convert(char(17),convert(money,round(pz.pret_cu_amanuntul*pz.cantitate,2)),1),4,14) as VALAM,
	substring(convert(char(18),convert(money,round((select sum(p.cantitate) from #pozdocFiltr p),2)),2),6,12) as TCANT,
	substring(convert(char(17),convert(money,round((select sum(round(p.cantitate*round((p.pret_cu_amanuntul/(1+convert(decimal(12,3),p.tva_neexigibil)/100)-p.pret_de_stoc),3),2)) from #pozdocFiltr p),2)),1),4,14) as TAD,
	substring(convert(char(17),convert(money,round((select sum(round(p.pret_cu_amanuntul*p.cantitate,2)) from #pozdocFiltr p),2)),1),4,14) as TOTALA,
	rtrim((case when exists(select 1 from par where tip_parametru='GE' and parametru ='LOCTERTI' and val_logica=1) then (select max(oras) from localitati loc where loc.cod_judet = t.judet and loc.cod_oras=t.localitate) else t.localitate end)) as LOC,
	rtrim((case when exists(select 1 from par where tip_parametru='GE' and parametru ='JUDTERTI ' and val_logica=1) then (select max(denumire) from judete jud where jud.cod_judet = t.judet) else t.judet end)) as JUD,
	@jud as JUDET,
	@loc as LOCALITATE,
	substring(convert(char(17),convert(money,round((select sum(round(p.pret_de_stoc*p.cantitate,2)) from #pozdocFiltr p),2)),1),4,14) as TVPA
		
	into #selectMare
	FROM 
	#PozDocFiltr pz
	LEFT JOIN terti t on t.Tert=pz.Tert and t.Subunitate=@Subunitate
	LEFT JOIN nomencl n on n.Cod = pz.Cod
	left join gestiuni g on pz.gestiune = g.cod_gestiune and g.subunitate = @subunitate
	left join anexadoc a on a.subunitate = @subunitate and a.tip='RD' and a.numar = pz.numar and a.data = pz.data
	
	ORDER BY pz.data_facturii, pz.factura

	SET @cTextSelect = '
	SELECT *
	into ' + @numeTabelTemp + '
	from #selectMare
	ORDER BY NR,DATA,COD
	'

	EXEC sp_executesql @statement = @cTextSelect

	/** 
		Daca sunt lucruri specifice de tratat ele vor fi evidentiate in procedura formReceptiiSP1
		prin interventie asupra tabelului @numeTabelTemp (fie alterari ale datelor, fie coloane noi, samd )
	**/
	if exists (select 1 from sysobjects where type='P' and name='formReceptiiSP1')
	begin
		exec formReceptiiSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
	end

	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'select * from ' + @numeTabelTemp

		EXEC sp_executesql @statement = @cTextSelect
	END
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+ ' (formReceptii)'
	raiserror(@mesaj, 11, 1)
end catch
