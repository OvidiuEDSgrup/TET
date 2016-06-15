/**
	Formularul este folosit pentru a lista Avize. 

**/
CREATE PROCEDURE formAvize @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
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
	SET @gestiune= isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),'')
		
	/* Alte **/
	
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	IF OBJECT_ID('tempdb..#PozDocFiltr') IS NOT NULL
		DROP TABLE #PozDocFiltr

	/** Pragatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre**/
	CREATE TABLE [dbo].[#PozDocFiltr] ([Numar] [varchar](20) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Pret_valuta] [float] NOT NULL, [Pret_de_stoc] [float] NOT NULL, 
		[Adaos] [real] NOT NULL, [Pret_vanzare] [float] NOT NULL, [Pret_cu_amanuntul] [float] NOT NULL, [TVA_deductibil] [float] NOT NULL, 
		[Cota_TVA] [real] NOT NULL, [Cod_intrare] [varchar](13) NOT NULL, [Locatie] [varchar](30) NOT NULL, [Data_expirarii] [datetime] NOT NULL, 
		[Loc_de_munca] [varchar](9) NOT NULL, [Comanda] [varchar](40) NOT NULL, [Barcod] [varchar](30) NOT NULL, 
		[Discount] [real] NOT NULL, [Tert] [varchar](13) NOT NULL, [Factura] [varchar](20) NOT NULL, 
		[Gestiune_primitoare] [varchar](40) NOT NULL, [Numar_DVI] [varchar](25) NOT NULL, [Valuta] [varchar](3) NOT NULL, [Curs] [float] NOT NULL, 
		[Data_facturii] [datetime] NOT NULL, [Data_scadentei] [datetime] NOT NULL, [Contract] [varchar](20) NOT NULL
		)

	INSERT INTO #PozDocFiltr (
		Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, 
		TVA_deductibil, Cota_TVA, Cod_intrare, Locatie, Data_expirarii, Loc_de_munca, Comanda, Barcod, Discount, Tert, 
		Factura, Gestiune_primitoare, Numar_DVI, Valuta, Curs, Data_facturii, Data_scadentei, Contract
		)
	SELECT rtrim(Numar), rtrim(Cod), max(Data) data, max(rtrim(Gestiune)), sum(Cantitate), max(Pret_valuta), max(Pret_de_stoc), 
		MAX(Adaos), max(Pret_vanzare), max(Pret_cu_amanuntul), sum(TVA_deductibil), max(Cota_TVA), rtrim(Cod_intrare), 
		MAX(rtrim(Locatie)), max(Data_expirarii), max(Loc_de_munca), max(rtrim(Comanda)), max(rtrim(Barcod)), 
		max(Discount), max(rtrim(pz.Tert)), rtrim(Factura), max(rtrim(Gestiune_primitoare)), max(Numar_DVI), max(Valuta), 
		max(Curs), max(Data_facturii), max(Data_scadentei), MAX(rtrim(Contract))
	FROM pozdoc pz
	
	WHERE pz.subunitate = @subunitate
		AND pz.tip = @tip
		AND pz.data = @data
		and pz.numar = @numar
		AND (@gestiune='' OR pz.Gestiune = @gestiune)
	group by pz.numar, pz.cod, pz.factura, pz.cod_intrare

	create index IX1 on #pozdocfiltr(numar,cod,cod_intrare)
	create index IX2 on #pozdocfiltr(cod)
	
	/**
		Informatiile din PAR sau similare se iau o singura data, nu in selectul principal care ar cauza rularea instructiunilor de multe ori
	*/
	SELECT @firma = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'NUME'
	SELECT @cui = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CODFISC'
	SELECT @ordreg = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'ORDREG'
	select @jud= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'JUDET'
	select @loc= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'SEDIU'
	select @adr=rtrim( val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'ADRESA'
	select @cont=rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CONTBC'
	select @banca= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'BANCA'
		
	/** Selectul principal	**/
	SELECT
	@firma as firma, @cui as cif, @ordreg as ordreg, @jud as jud, @loc as loc, @adr as adr, @cont as cont, @banca as banca, 
	rtrim(t.denumire) as DENUMIRE,
	rtrim(t.cod_fiscal) as CUI,
	rtrim(t.localitate) as LOCALITATE,
	rtrim(t.judet) as JUDET,
	convert(CHAR(10),pz.data,103) as DATA,
	rtrim(t.cont_in_banca) as CONTTERT,
	rtrim(pz.numar) as NUMAR,
	rtrim(t.banca) as BANCATERT,
	row_number() OVER(ORDER BY pz.cod) as NRCRT,
	(case when pz.barcod='' then rtrim(pz.cod)+'-'+n.denumire else rtrim(pz.barcod)+'-'+(select nomspec.denumire from nomspec where  pz.barcod=nomspec.cod_special and pz.cod=nomspec.cod and pz.tert=nomspec.tert) end) as explicatie,
	left(convert(char(18),convert(money,round(pz.discount,3)),2),17) as PDISC,
	left(convert(char(18),convert(money,round(pz.cantitate,3)),2),17) as cant,
	left(convert(char(18),convert(money,round(pz.pret_cu_amanuntul,2)),2),17) as PRAPRE,
	n.um as um,
	left(convert(char(18),convert(money,round(pz.cantitate*pz.pret_cu_amanuntul,2)),2),17) AS valoare,
	(case when (select sum(p.discount) from #PozDocFiltr p where p.numar=pz.numar and p.data=pz.data)>0 then convert(char(15),convert(money,round((select sum(p.cantitate*p.pret_valuta) from #PozDocFiltr p where p.numar=pz.numar and p.data=pz.data),2)),1) else '' end) AS TOTFDISC,
	convert(char(15),convert(money,round((select sum(p.cantitate*p.pret_vanzare) from #PozDocFiltr p where p.numar=pz.numar and p.data=pz.data),2)),1) as TOTAL,
	a.seria_buletin as sr, a.numar_buletin as nrib, a.eliberat as elib, a.mijloc_de_transport as mijloctransp, a.numarul_mijlocului as nrmij,
	convert(CHAR(10),a.data_expedierii,103) as dataexp, left(a.ora_expedierii,2)+':'+substring(a.ora_expedierii,3,2) oraexp,
	@utilizator AS intocmit,
	convert(char(17),convert(money,round((select (sum(p.pret_cu_amanuntul*p.cantitate)) from #PozDocFiltr p where p.numar=pz.numar and p.data=pz.data),2)),1) as TOTCUTVA
	
	into #selectMare
	FROM 
	#PozDocFiltr pz
	LEFT JOIN terti t on t.Tert=pz.Tert and t.Subunitate=@Subunitate
	LEFT JOIN nomencl n on n.Cod=pz.Cod
	LEFT join anexadoc a on a.tip = 'AP' and a.numar = pz.numar and a.data = pz.data and a.subunitate = @subunitate 
	
	ORDER BY pz.data, pz.numar

	SET @cTextSelect = '
	SELECT *
	into ' + @numeTabelTemp + '
	from #selectMare
	ORDER BY data,numar,NRCRT
	'

	EXEC sp_executesql @statement = @cTextSelect

	/** 
		Daca sunt lucruri specifice de tratat ele vor fi evidentiate in procedura formReceptiiSP1
		prin interventie asupra tabelului @numeTabelTemp (fie alterari ale datelor, fie coloane noi, samd )
	**/
	if exists (select 1 from sysobjects where type='P' and name='formAvizeSP1')
	begin
		exec formAvizeSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
	end

	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'select * from ' + @numeTabelTemp

		EXEC sp_executesql @statement = @cTextSelect
	END
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (formAvize)'
	raiserror(@mesaj, 11, 1)
end catch
