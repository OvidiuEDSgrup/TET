--/*
IF EXISTS (SELECT * FROM sys.objects WHERE NAME = 'rapFormReceptieAmSP')
	DROP PROCEDURE rapFormReceptieAmSP
GO
/**
	Procedura de luare a datelor pentru formularul web (rdl) "Formular receptie"

--**/
CREATE PROCEDURE rapFormReceptieAmSP --*/DECLARE
@sesiune VARCHAR(50), @tip varchar(2), @numar varchar(20), @data datetime,
	@datajos datetime=null, @datasus datetime=null, @f_gestprim varchar(50)=null
	,@parXML varchar(max)
/*
SELECT @sesiune=N'DC8053634E7B4',@tip=N'TE',@numar=N'GL70001',@data='2014-05-27 00:00:00',@datajos=NULL,@datasus=NULL,@f_gestprim=NULL,@parXML=NULL
--*/AS
begin try 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @unitate VARCHAR(100), @mesaj varchar(1000), @subunitate varchar(10), @cui VARCHAR(100), 
			@ordreg VARCHAR(100), @jud VARCHAR(100), @loc varchar(100), 
			@cont VARCHAR(100), @banca varchar(100), @gestiune varchar(20), @factura varchar(20), @grupaTerti varchar(20),
			@utilizator varchar(50), @filtruFacturi bit

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	IF OBJECT_ID('tempdb..#PozDocFiltr') IS NOT NULL
		DROP TABLE #PozDocFiltr

	/** Pregatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre**/
	CREATE TABLE [dbo].[#PozDocFiltr] (Tip varchar(2) not null,[Numar] [varchar](8) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Pret_valuta] [float] NOT NULL, [Pret_de_stoc] [float] NOT NULL, 
		[Adaos] [real] NOT NULL, [Pret_vanzare] [float] NOT NULL, [Pret_cu_amanuntul] [float] NOT NULL, [TVA_deductibil] [float] NOT NULL, 
		[Cota_TVA] [real] NOT NULL, [Cod_intrare] [varchar](13) NOT NULL, [TVA_neexigibil] [real] NOT NULL, [Locatie] [varchar](30) NOT NULL, [Data_expirarii] [datetime] NOT NULL, 
		[Loc_de_munca] [varchar](9) NOT NULL, [Comanda] [varchar](40) NOT NULL, [Barcod] [varchar](30) NOT NULL, 
		[Discount] [real] NOT NULL, [Tert] [varchar](13) NOT NULL, [Factura] [varchar](20) NOT NULL, 
		[Gestiune_primitoare] [varchar](13) NOT NULL, [Numar_DVI] [varchar](25) NOT NULL, [Valuta] [varchar](3) NOT NULL, [Curs] [float] NOT NULL, 
		[Data_facturii] [datetime] NOT NULL, [Data_scadentei] [datetime] NOT NULL, [Contract] [varchar](20) NOT NULL
		)

	INSERT INTO #PozDocFiltr (		
		Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, 
		TVA_deductibil, Cota_TVA, Cod_intrare, tva_neexigibil, Locatie, Data_expirarii, Loc_de_munca, Comanda, Barcod, Discount, Tert, 
		Factura, Gestiune_primitoare, Numar_DVI, Valuta, Curs, Data_facturii, Data_scadentei, Contract
		)
	SELECT rtrim(max(p.Tip)), rtrim(max(Numar)), rtrim(p.Cod), max(Data) data, max(rtrim(p.Gestiune)), sum(Cantitate), max(Pret_valuta), max(Pret_de_stoc), 
		MAX(Adaos), max(p.Pret_vanzare), max(p.Pret_cu_amanuntul), sum(TVA_deductibil), max(p.Cota_TVA), MAX(rtrim(Cod_intrare)), MAX(tva_neexigibil),
		MAX(rtrim(Locatie)), max(Data_expirarii), max(p.Loc_de_munca), max(rtrim(Comanda)), max(rtrim(Barcod)), 
		max(Discount), max(rtrim(p.Tert)), rtrim(Factura), max(rtrim(Gestiune_primitoare)), max(Numar_DVI), max(p.Valuta), 
		max(Curs), Data_facturii, max(Data_scadentei), MAX(rtrim(Contract))
	FROM pozdoc p join nomencl n on n.Cod=p.Cod and n.Tip<>'S'
	
	WHERE p.subunitate = @subunitate
		AND p.tip = @tip
		and (p.Numar = @numar or @numar is null)
		and (p.Data between ISNULL(@datajos,@data) and ISNULL(@datasus,@data))
		and (@f_gestprim is null or p.Gestiune_primitoare=@f_gestprim)
	group by p.factura, p.data_facturii, p.cod
	

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
	row_number() OVER(ORDER BY pz.cod) as NR,	rtrim(pz.cod) as COD,
	ltrim(rtrim(g.denumire_gestiune)) as GEST,	rtrim(ltrim(t.denumire)) as FURN,	rtrim(ltrim(pz.factura)) as FACT,	rtrim(n.denumire) as DENUMIRE,	n.um as UM,	pz.pret_de_stoc as PRET,	round(pz.cantitate,2) as CANT,	round(pz.pret_de_stoc*pz.cantitate,2) as VAL,	round(pz.pret_cu_amanuntul*convert(decimal(12,2),pz.tva_neexigibil)/(100+convert(decimal(12,2),pz.tva_neexigibil))*pz.cantitate,2) as TVA,	round(pz.pret_cu_amanuntul*convert(decimal(12,2),pz.tva_neexigibil)/(100+convert(decimal(12,2),pz.tva_neexigibil)),2) as TVAUNIT,	round((select sum(p.pret_de_stoc*p.cantitate) from #PozDocFiltr p where p.data=pz.data and p.numar=pz.numar),2) as TVAL,	round((select sum(round(p.pret_cu_amanuntul*convert(decimal(12,2),p.tva_neexigibil)/(100+convert(decimal(12,2),p.tva_neexigibil))*p.cantitate,2)) 		from #PozDocFiltr p where p.numar=pz.numar and p.data=pz.data),2) as TTVA,	round((select (sum(p.pret_de_stoc*p.cantitate)+sum(p.TVA_deductibil)) from #PozDocFiltr p where p.numar=pz.numar and p.data=pz.data),2) as TOTAL,
	a.numele_delegatului as MEMBR1,	a.eliberat as MEMBR2,	a.mijloc_de_transport AS MEMBR3,
	a.observatii as MEMBR4,	-- pentru receptii in pret cu amanuntul	round(pz.pret_cu_amanuntul/(1+convert(decimal(12,2),pz.tva_neexigibil)/100),2) as PRVANZ,	round(pz.cantitate*(pz.pret_cu_amanuntul/(1+convert(decimal(12,2),pz.tva_neexigibil)/100)),2) as VALPRVANZ,	round(n.pret_cu_amanuntul,2) as PRETV,	round(n.pret_cu_amanuntul*pz.cantitate,2) as VALPV,	round((pz.pret_cu_amanuntul/(1+convert(decimal(12,2),pz.tva_neexigibil)/100)-pz.pret_de_stoc),2) as ADUNIT,	round(pz.cantitate*(pz.pret_cu_amanuntul/(1+convert(decimal(12,2),pz.tva_neexigibil)/100)-pz.pret_de_stoc),2) as AD,	round(pz.pret_cu_amanuntul,2) as PRAM,	round(pz.pret_cu_amanuntul*pz.cantitate,2) as VALAM,	round((select sum(p.cantitate) from #pozdocFiltr p),2) as TCANT,
	round((select sum(round(p.cantitate*round((p.pret_cu_amanuntul/(1+convert(decimal(12,3),p.tva_neexigibil)/100)-p.pret_de_stoc),3),2)) from #pozdocFiltr p),2) as TAD,
	round((select sum(round(p.pret_cu_amanuntul*p.cantitate,2)) from #pozdocFiltr p),2) as TOTALA,
	rtrim((case when exists(select 1 from par where tip_parametru='GE' and parametru ='LOCTERTI' and val_logica=1) then (select max(oras) from localitati loc where loc.cod_judet = t.judet and loc.cod_oras=t.localitate) else t.localitate end)) as LOC,	rtrim((case when exists(select 1 from par where tip_parametru='GE' and parametru ='JUDTERTI ' and val_logica=1) then (select max(denumire) from judete jud where jud.cod_judet = t.judet) else t.judet end)) as JUD,
	@jud as JUDET,
	@loc as LOCALITATE,
	round((select sum(round(p.pret_de_stoc*p.cantitate,2)) from #pozdocFiltr p),2) as TVPA
	,round((select sum(round((p.pret_cu_amanuntul/(1+convert(decimal(12,2),p.tva_neexigibil)/100))*p.cantitate,2)) from #pozdocFiltr p),2) as TVPV
		
	FROM 
	#PozDocFiltr pz
	LEFT JOIN terti t on t.Tert=pz.Tert and t.Subunitate=@Subunitate
	LEFT JOIN nomencl n on n.Cod = pz.Cod
	left join gestiuni g on pz.gestiune = g.cod_gestiune and g.subunitate = @subunitate
	left join anexadoc a on a.subunitate = @subunitate and a.tip=pz.tip and a.numar = pz.numar and a.data = pz.data
	
	ORDER BY pz.data_facturii, pz.factura

end try
begin catch
	set @mesaj = ERROR_MESSAGE()+ ' (rapFormReceptieAmSP)'
	raiserror(@mesaj, 11, 1)
end catch

/*
	exec rapFormReceptieAmSP @sesiune='', @tip='RM', @numar='97', @data='2013-06-30'
*/