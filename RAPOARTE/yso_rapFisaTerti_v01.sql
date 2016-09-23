--***	Procedura pentru raportul CG\Financiar\Fisa terti si Fisa terti pe intervale
/***	--> exemplu de apel:
	
	exec yso_rapFisaTerti_v01 @sesiune='',@cFurnBenef=N'F',@cData='2014-12-31',@cTert=NULL,@judet=NULL,@cFactura=null,@cContTert=NULL,@soldmin=N'0.01',@soldabs=0,@dDataFactJos=NULL,@dDataFactSus=NULL,
	@dDataScadJos=NULL,@dDataScadSus=NULL,@aviz_nefac=N'0',@grupa=NULL,@grupa_strict=N'0',@exc_grupa=NULL,@fsolddata1=0,@comanda=NULL,@indicator=NULL,@cDataJos=NULL,@tipdoc=N'F',@locm=NULL,@punctLivrare=NULL,@fsold=0,
	@moneda=N'0',@valuta=NULL,@centralizare=N'0',@gestiune=NULL,@soldcumulat=0,@ordonare=N'0',@grupare=N'GR'

--*/	

--/*
if exists (select * from sysobjects where name ='yso_rapFisaTerti_v01')
drop procedure yso_rapFisaTerti_v01
go --*/
--/***
CREATE procedure yso_rapFisaTerti_v01(--*/ declare
	@sesiune varchar(50)=null,
	@cFurnBenef varchar(1), @cData datetime, @cTert varchar(50) = null, @cFactura varchar(50) = null, @cContTert varchar(50) = null,
	@soldmin decimal(20,2)=0.01, @soldabs int=0, @dDataFactJos datetime=null, @dDataFactSus datetime=null, @dDataScadJos datetime=null,@dDataScadSus datetime=null,
	@aviz_nefac int = 0, @grupa varchar(50) = null, @grupa_strict int=0, @exc_grupa varchar(50)=null,
	@fsolddata1 int=0, 
	@fsold int=2,	--> @fsold=facturi pe sold; echivalenta cu : 1 => @soldmin=0.01 si @soldabs=1; 0 => @soldmin=0.00 si @soldabs=1
	@comanda varchar(50) = null, @indicator varchar(50) = null, @cDataJos datetime = null, 
	@tipdoc varchar(1) = 'F',	-->	sursa:	F=Facturi, E=Efecte, X=Toate
	@locm varchar(20) = null,
	@punctLivrare varchar(20) = null,
	@moneda bit=0, @valuta varchar(20)=null,
	@centralizare int=0,	--> prin parametrul centralizare se determina ordonarea datelor; daca 0=facturi se ord pe facturi, daca 1=documente se ord pe documente
	@gestiune varchar(20)=null,
	@soldcumulat bit=0,	--> daca se calculeaza sold cumulat sau ramane sold normal
	@cuefecte bit=1,	--> sa fie aduse facturile achitate prin efecte: 0, null = nu se aplica, 1 = se aduc doar cele cu efecte neachitate
	@judet varchar(100)=null,	-->	judet tert
	@inclFacturiNe bit=1,		--> include facturi nesosite/neintocmite
	@ordonare int=1,		--> 0 = cod, 1 = denumire
	@grupare varchar(100)='UN'	/*	"UN"=unitate,tert
									"GR"=grupa terti,tert
									"LM"=loc de munca,tert
									"CO"=comanda,tert
									"IB"=indicator bugetar,tert
									"TE"=tert,tip
									"PL"=tert, punct livrare
									"CT"=cont de tert, tert
								*/
/*
--@sesiune nvarchar(14),@cFurnBenef nvarchar(1),@cData datetime,@cTert nvarchar(10),@judet nvarchar(4000),@cFactura nvarchar(4000),@cContTert nvarchar(4000),@soldmin nvarchar(4),@soldabs int,@dDataFactJos nvarchar(4000),@dDataFactSus nvarchar(4000),@dDataScadJos nvarchar(4000),@dDataScadSus nvarchar(4000),@aviz_nefac nvarchar(1),@grupa nvarchar(4000),@grupa_strict nvarchar(1),@exc_grupa nvarchar(4000),@fsolddata1 bit,@comanda nvarchar(4000),@indicator nvarchar(4000),@cDataJos nvarchar(4000),@tipdoc nvarchar(1),@locm nvarchar(4000),@punctLivrare nvarchar(4000),@fsold bit,@moneda nvarchar(1),@valuta nvarchar(4000),@centralizare nvarchar(1),@gestiune nvarchar(4000),@soldcumulat bit,@ordonare nvarchar(1),@grupare nvarchar(2),@cuefecte bit
select @sesiune=N'',@cFurnBenef=N'B',@cData='2016-03-31 00:00:00',@cTert=N'1741013270591',@judet=NULL,@cFactura=NULL,@cContTert=NULL,@soldmin=N'0.01',@soldabs=0,@dDataFactJos=NULL,@dDataFactSus=NULL,@dDataScadJos=NULL,@dDataScadSus=NULL,@aviz_nefac=N'0',@grupa=NULL,@grupa_strict=N'0',@exc_grupa=NULL,@fsolddata1=0,@comanda=NULL,@indicator=NULL,@cDataJos=NULL,@tipdoc=N'X',@locm=NULL,@punctLivrare=NULL,@fsold=0,@moneda=N'0',@valuta=NULL,@centralizare=N'0',@gestiune=NULL,@soldcumulat=0,@ordonare=N'0',@grupare=N'TE',@cuefecte=1
--*/)as
begin	
/*	--	Valori pentru teste
declare @cFurnBenef nvarchar(1),@cData datetime,@cTert nvarchar(7),@cFactura nvarchar(4000),
	@cContTert nvarchar(4000),@soldmin nvarchar(4),	@soldabs int,@dDataFactJos nvarchar(4000),
	@dDataFactSus nvarchar(4000),@dDataScadJos nvarchar(4000),@dDataScadSus nvarchar(4000),
	@aviz_nefac nvarchar(1),@grupa nvarchar(4000),@grupa_strict nvarchar(1),
	@exc_grupa nvarchar(4000),@fsolddata1 int, @comanda nvarchar(4000),@indicator nvarchar(4000),
	@cDataJos datetime, @tipdoc varchar(1), @locm varchar(20)
select @cFurnBenef=N'F',@cData='2011-08-31 00:00:00',--@cTert=N'253232 ',
	@cFactura=NULL,@cContTert=NULL,@soldmin=N'1', @soldabs=0,@dDataFactJos=NULL,
	@dDataFactSus=NULL,@dDataScadJos=NULL,@dDataScadSus=NULL,@aviz_nefac=N'0',@grupa=NULL,
	@grupa_strict=N'0',@exc_grupa=NULL,@fsolddata1=0,@comanda=NULL,@indicator=NULL,
	@cDataJos='2011-1-1 00:00:00', @tipdoc='x', @locm='11'
--*/
	set transaction isolation level read uncommitted
	--> evitare "parameter sniffing":
		declare @q_sesiune varchar(50), @q_cFurnBenef varchar(1), @q_cData datetime, @q_cTert varchar(50), @q_cFactura varchar(50), @q_cContTert varchar(50),
			@q_soldmin decimal(20,2), @q_soldabs int, @q_dDataFactJos datetime, @q_dDataFactSus datetime, @q_dDataScadJos datetime,
			@q_dDataScadSus datetime, @q_aviz_nefac int, @q_grupa varchar(50), @q_grupa_strict int, @q_exc_grupa varchar(50),
			@q_fsolddata1 int, @q_fsold int, @q_comanda varchar(50), @q_indicator varchar(50), @q_cDataJos datetime, @q_tipdoc varchar(1),
			@q_locm varchar(20), @q_punctLivrare varchar(20), @q_moneda bit, @q_valuta varchar(20), @q_centralizare int,
			@q_gestiune varchar(20), @q_soldcumulat bit
				
		select @q_sesiune=@sesiune, @q_cFurnBenef=@cFurnBenef, @q_cData=@cData, @q_cTert=@cTert, @q_cFactura=@cFactura, @q_cContTert=@cContTert,
			@q_soldmin=@soldmin, @q_soldabs=@soldabs, @q_dDataFactJos=@dDataFactJos, @q_dDataFactSus=@dDataFactSus, @q_dDataScadJos=@dDataScadJos,
			@q_dDataScadSus=@dDataScadSus, @q_aviz_nefac=@aviz_nefac, @q_grupa=@grupa, @q_grupa_strict=@grupa_strict, @q_exc_grupa=@exc_grupa,
			@q_fsolddata1=@fsolddata1, @q_fsold=@fsold, @q_comanda=@comanda, @q_indicator=@indicator, @q_cDataJos=@cDataJos, @q_tipdoc=@tipdoc,
			@q_locm=@locm+'%', @q_punctLivrare=@punctLivrare, @q_moneda=@moneda, @q_valuta=@valuta, @q_centralizare=@centralizare,
			@q_gestiune=@gestiune, @q_soldcumulat=@soldcumulat
			
	declare @q_deNesters bit, @parXML xml, @parXMLFact xml
	select @q_deNesters=0, @parXML=(select @sesiune as sesiune, isnull(@cuefecte,1) as efecteachitate for xml raw)
	if object_Id('tempdb.dbo.#fFacturi') is not null drop table #fFacturi
	IF OBJECT_ID('tempdb..#raport') IS NOT NULL drop table #raport
	IF OBJECT_ID('tempdb..#facturiCuGestiuni') IS NOT NULL drop table #facturiCuGestiuni
declare @q_eroare varchar(1000)
set @q_eroare=''
begin try

	if object_id('tempdb..#fisa') is null
	begin
		create table #fisa (ceva char(1) default '')
		exec rapFisaTerti_structFisa
	end
	
	declare @q_utilizator varchar(50), @cuFiltruLM bit
	select @q_utilizator=dbo.fiautilizator(@q_sesiune), @cuFiltruLM=0
	if @q_cdata is null and exists (select 1 from lmfiltrare l where l.utilizator=@q_utilizator)
		select @cuFiltruLM=1

	declare @q_dataImplementarii datetime,
			@q_dataSolduri datetime		/**	data pana la care orice sume vor aparea ca solduri = data implementarii sau data ultimei initializari;
											daca nu e completat @q_cdatajos va fi @q_datasolduri*/
			, @lDPreImpl int, @dDPreImpl datetime  -- o setare care spune ca am date initiale anterioare factimpl, tinute in istfact 
	select @q_dataImplementarii=--'1921-1-1'
	dateadd(d,-1,
		dateadd(m,1,
		isnull((select convert(varchar(4),val_numerica) from par where tip_parametru='ge' and parametru='ANULIMPL'),'1921')+'-'+
		isnull((select convert(varchar(2),val_numerica) from par where tip_parametru='ge' and parametru='lunaimpl'),'1')+'-1'
		)),
		@q_dataSolduri=(select max(case when parametru='ANULINC' then convert(varchar(20),val_numerica) else '' end)+'-'
								+max(case when parametru='LUNAINC' then convert(varchar(20),val_numerica) else '' end)+'-1'
						from par p where tip_parametru='GE' and parametru in ('ANULINC','LUNAINC'))
		
		if (@q_dataSolduri<@q_dataImplementarii) set @q_dataSolduri=@q_dataImplementarii
	--*/
	select	@lDPreImpl=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='PREIMPL'),0), 
			@dDPreImpl=isnull((select max(convert(datetime,val_alfanumerica)) from par where tip_parametru='GE' and parametru='PREIMPL'),'1901-01-01')

	declare @q_soldmin_f varchar(20), @q_tipef varchar(1)
	select @q_soldmin_f=0.00,
		@q_tipef=(case when @q_cFurnBenef='F' then 'P' else 'I' end)
	
	declare @q_avemDataJos int	select @q_avemDataJos=1
	if (@q_cDataJos is null)
	begin
		set @q_cDataJos='1921-1-1'
		--set @q_fsolddata1=0
		set @q_avemDataJos=0
		--set @q_soldmin_f=@q_soldmin
	end
	set @q_cDataJos=dateadd(d,-1,@q_cDataJos)
	if(@q_cDataJos<@q_dataSolduri and @q_avemDataJos=0)
	begin
			 -- set @q_soldmin_f=@q_soldmin
			  set @q_cDataJos=@q_dataSolduri
	end
	if @lDPreImpl=1 and @q_cData<=@q_dataImplementarii
		set @q_cDataJos=@dDPreImpl
	

	exec rapFisaTerti @sesiune=@sesiune, @cFurnBenef=@cFurnBenef,@cData=@cData,@cTert=@cTert,@cFactura=@cFactura,@cContTert=@cContTert,@soldmin=@soldmin,
		@soldabs=@soldabs,@dDataFactJos=@dDataFactJos,@dDataFactSus=@dDataFactSus,@dDataScadJos=@dDataScadJos,@dDataScadSus=@dDataScadSus,
		@aviz_nefac=@aviz_nefac,@grupa=@grupa,@grupa_strict=@grupa_strict,@exc_grupa=@exc_grupa,@fsolddata1=@fsolddata1,
		@comanda=@comanda,@indicator=@indicator,@cDataJos=@cDataJos, @tipdoc=@tipdoc, @locm=@locm, @punctLivrare=@punctLivrare,
		@fsold=@fsold, @moneda=@moneda, @valuta=@valuta, @centralizare=@centralizare, @gestiune=@gestiune, @soldcumulat=@soldcumulat, @judet=@judet,
		@inclFacturiNe=@inclFacturiNe, @ordonare=@ordonare, @grupare=@grupare, @cuefecte=@cuefecte

	 declare @userASiS varchar(10), @fltLmUt int  
	 set @userASiS=dbo.fIaUtilizator(null)  
	 declare @LmUtiliz table(valoare varchar(200), cod varchar(20))  
	  
	 insert into @LmUtiliz (valoare,cod)  
	 select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='LOCMUNCA' and valoare<>''  
	 set @fltLmUt=isnull((select count(1) from @LmUtiliz),0)  
	
	declare @fltGstUt int
	declare @GestUtiliz table(valoare varchar(200), cod varchar(20), analitic371 varchar(20), analitic707 varchar(20))
	insert into @GestUtiliz (valoare,cod, analitic371, analitic707)
	select valoare, cod_proprietate,
			'371'+'.'+rtrim(cod_proprietate)+'%' analitic371, '707'+'.'+rtrim(cod_proprietate)+'%' analitic707 from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>''
	set	@fltGstUt=isnull((select count(1) from @GestUtiliz),0)

	declare @CtDocFaraFact varchar(200)
	set @CtDocFaraFact=isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='NEEXDOCFF'),''),'408,418')
	
	select c.cont into #ctdocfarafact
	from dbo.fSplit(@CtDocFaraFact,',') ff
		left outer join conturi c on c.subunitate='1' and c.cont like rtrim(ff.string)+'%'	

	insert into #fisa(sursa,
		denumire, oras, furn_benef, subunitate, tert, factura, tip, numar, data,
		soldi, valoare, tva, total, achitat
		, valuta, curs, loc_de_munca, comanda, cont_de_tert, fel, cont_coresp, explicatii, numar_pozitie,
		gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, soldf, sold_cumulat,
		soldi_valuta, valoare_valuta, tva_valuta, total_valuta, achitat_valuta, soldf_valuta, sold_cumulat_valuta,
		ordonare, achitat_efect, indicator, grupare1, denumire1, grupare2, denumire2)
	select 'C' sursa
		, t.denumire, l.oras, 'B' furn_benef, p.subunitate subunitate, p.tert, p.Factura, p.tip, p.numar, p.data
		, 0 soldi, round(convert(decimal(18,5),cantitate*p.pret_vanzare),2) valoare, p.TVA_deductibil tva 
		, round(convert(decimal(18,5),cantitate*p.pret_vanzare),2)+p.TVA_deductibil total
		, round(convert(decimal(18,5),cantitate*p.pret_vanzare),2)+p.TVA_deductibil achitat
		, p.valuta,	p.curs, p.loc_de_munca, p.comanda, p.Cont_factura cont_de_tert, '2' fel, p.Cont_de_stoc cont_coresp,rtrim(n.Denumire) explicatii, p.numar_pozitie
		, p.Gestiune, p.Data_facturii, p.data_scadentei as data_scadentei, '' nr_dvi, p.Barcod, p.idPozDoc
		, 0 peSold
		, 0 soldf
		, 0 sold_cumulat, 0 soldi_valuta, 0 valoare_valuta, 0 tva_valuta, 0 total_valuta, 0 achitat_valuta, 0 soldf_valuta, 0 sold_cumulat_valuta
		, '' ordonare,0 achitat_efect, substring(p.comanda,21,20), '', '', '', ''
	from pozdoc p 
		left outer join lmfiltrare pr on pr.cod=p.loc_de_munca and pr.utilizator=@q_utilizator
		left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
		left outer join nomencl n on n.cod=p.cod
		left outer join mfix on isnull(n.tip, '')='F' and mfix.subunitate=p.subunitate and mfix.numar_de_inventar=p.cod_intrare
		left outer join gterti g on t.grupa=g.grupa
		left outer join lm on p.loc_de_munca=lm.cod
		left outer join localitati l on t.localitate=l.cod_oras
	where p.subunitate='1' and p.tip in ('AC') and p.cont_factura='' 
		and p.data between @q_cDataJos and @q_cData
		and (@q_cTert is null or p.tert like rtrim(@q_ctert)) 
		and (@q_cFactura is null or p.factura like rtrim(@q_cFactura)) 
		and (@cuFiltruLM=0 or pr.utilizator=@q_utilizator	)
		and (@q_locm is null or convert(char(9),p.Loc_de_munca) like @q_locm)
		and p.data_scadentei between isnull(@q_dDataScadJos,'1901-1-1') and isnull(@q_dDataScadSus,'2999-1-1')
		and (@q_comanda is null or left(p.comanda,20)=@q_comanda) 
		and (@fltLmUt=0 or exists(select 1from @LmUtiliz pr where pr.valoare=p.Loc_de_munca))
		and (@fltGstUt=0 or exists(select 1from @GestUtiliz pr where pr.valoare=p.Gestiune))
	
	alter table #fisa add categ_yso varchar(50) null, ord_categ_yso int null
		, total_facturi_avans decimal(15,4), achitat_facturi_avans decimal(15,4)
		, total_facturi_marfa decimal(15,4), achitat_facturi_marfa decimal(15,4)
		, total_facturi_servicii decimal(15,4), achitat_facturi_servicii decimal(15,4)
		, total_bonuri_avans decimal(15,4), achitat_bonuri_avans decimal(15,4)
		, total_bonuri_marfa decimal(15,4), achitat_bonuri_marfa decimal(15,4)
		, total_bonuri_servicii decimal(15,4), achitat_bonuri_servicii decimal(15,4)
		, total_incasari decimal(15,4), achitat_incasari decimal(15,4)
		, total_instrumente_incasare decimal(15,4), achitat_instrumente_incasare decimal(15,4)
		, total_compensari decimal(15,4), achitat_compensari decimal(15,4)
		, total_alte_operatii decimal(15,4), achitat_alte_operatii decimal(15,4)
	
	update f set 
		categ_yso=(case 
				when f.cont_de_tert like '411%' and f.cont_coresp like '472%' then 'Facturi_avans_informativ'
				when c.cont is not null and f.cont_coresp like '472%' then 'Avize_nefacturate_avans_informativ'
				when f.cont_de_tert like '411%' and f.cont_coresp like '707%' then 'Facturi_marfa'
				when c.cont is not null and f.cont_coresp like '707%' then 'Avize_nefacturate_marfa'
				when f.cont_de_tert like '411%' and f.cont_coresp like '70[48]%' then 'Facturi_servicii'
				when c.cont is not null and f.cont_coresp like '70[48]%' then 'Avize_nefacturate_servicii'
				when c.cont is not null and f.cont_coresp like '411%' then 'Intocmiri_facturi_avize_nefacturate'
				when f.cont_de_tert='' and f.cont_coresp like '472%' then 'Bonuri_avans_informativ'
				when f.cont_de_tert='' and f.cont_coresp like '371%' then 'Bonuri_marfa'
				when f.cont_de_tert='' and f.cont_coresp like '70[48]%' then 'Bonuri_servicii'
				when f.cont_de_tert like '411%' and (f.cont_coresp like '5311%' or f.cont_coresp like '512%' or f.cont_coresp like '413%') then 'Incasari'
				when f.cont_de_tert like '413%' and (f.cont_coresp like '411%' or f.cont_coresp like '512%' or f.cont_coresp like '5311%') then 'Instrumente_incasare'
				when f.cont_de_tert like '411%' and f.cont_coresp like '4735%' then 'Compensari'
				else 'Alte_operatii' end)
	from #fisa f left join #ctdocfarafact c on c.Cont=f.cont_de_tert
	
	update f set 
		ord_categ_yso=(case f.categ_yso 
				when 'Facturi_avans_informativ' then 10
				when 'Avize_nefacturate_avans_informativ' then 15
				when 'Facturi_marfa' then 20
				when 'Avize_nefacturate_marfa' then 25
				when 'Facturi_servicii' then 30
				when 'Avize_nefacturate_servicii' then 35
				when 'Intocmiri_facturi_avize_nefacturate' then 37
				when 'Bonuri_avans informativ' then 40
				when 'Bonuri_marfa' then 50
				when 'Bonuri_servicii' then 60
				when 'Incasari' then 70
				when 'Instrumente_incasare' then 80
				when 'Compensari' then 90
				when 'Alte_operatii' then 100
				else 200 end)
	from #fisa f;

	;WITH Fisa AS (
	select sursa,
			rtrim(f.denumire) denumire, oras, furn_benef, f.subunitate, f.tert, rtrim(factura) factura, tip,
			rtrim(numar) numar, data,
			soldi, valoare, tva, total, achitat, valuta, curs, rtrim(loc_de_munca) loc_de_munca,
			left(comanda,20) comanda, rtrim(cont_de_tert) cont_de_tert, fel, rtrim(cont_coresp) cont_coresp
			, rtrim(explicatii) explicatii,
			numar_pozitie,
			gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, soldf, sold_cumulat,
			soldi_valuta, valoare_valuta, tva_valuta, total_valuta, achitat_valuta, soldf_valuta,
			sold_cumulat_valuta, ordonare, f.indicator indicator,
			rtrim(t.grupa) as gtert, rtrim(g.denumire) dengtert, rtrim(l.denumire) as denlm,
			rtrim(t.grupa) as grupa, rtrim(i.descriere) as den_pctlivrare, grupare1, denumire1,
			grupare2, denumire2
			, f.categ_yso, f.ord_categ_yso
		from #fisa f left join terti t on t.subunitate=f.subunitate and f.tert=t.tert
			left join gterti g on t.grupa=g.grupa
			left join lm l on f.loc_de_munca=l.cod
			left join infotert i on i.subunitate=t.subunitate and i.tert=f.tert and i.identificator=f.nr_dvi
		union all -- anulez achitarile cu efecte, daca efectul este pe sold
		select sursa,
			f.denumire, oras, furn_benef, f.subunitate, f.tert, rtrim(factura) factura, tip, rtrim(numar) numar, data,
			soldi, achitat_efect valoare, tva, 0 total, -achitat_efect achitat, valuta, curs, rtrim(loc_de_munca) loc_de_munca,
			left(comanda,20) comanda, rtrim(cont_de_tert) cont_de_tert, fel, rtrim(cont_coresp) cont_coresp,
			rtrim(explicatii) explicatii, numar_pozitie,
			gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, achitat_efect soldf, sold_cumulat,
			soldi_valuta, valoare_valuta, tva_valuta, total_valuta, achitat_valuta, soldf_valuta, sold_cumulat_valuta,
			ordonare, f.indicator indicator,
			rtrim(t.grupa) as gtert, rtrim(g.denumire) dengtert, rtrim(l.denumire) as denlm, rtrim(t.grupa) as grupa,
			rtrim(i.descriere) as den_pctlivrare, grupare1, denumire1, grupare2, denumire2
			, f.categ_yso, f.ord_categ_yso
		from #fisa f left join terti t on t.subunitate=f.subunitate and f.tert=t.tert
			left join gterti g on t.grupa=g.grupa
			left join lm l on f.loc_de_munca=l.cod
			left join infotert i on i.subunitate=t.subunitate and i.tert=f.tert and i.identificator=f.nr_dvi
		where (@cuefecte=1 and abs(achitat_efect)>0.001)
		--union all --/* anulez valoarea facturilor de avans (cont coresp 472)
		--select sursa,
		--	rtrim(f.denumire) denumire, oras, furn_benef, f.subunitate, f.tert, rtrim(factura) factura, tip,
		--	rtrim(numar) numar, data,
		--	soldi,0 valoare,0 tva,0 total,0 achitat, valuta, curs, rtrim(loc_de_munca) loc_de_munca,
		--	left(comanda,20) comanda, rtrim(cont_de_tert) cont_de_tert, fel, rtrim(cont_coresp) cont_coresp
		--	, rtrim(explicatii) explicatii,
		--	numar_pozitie,
		--	gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, -total soldf, sold_cumulat,
		--	soldi_valuta, valoare_valuta, tva_valuta, total_valuta, achitat_valuta, soldf_valuta,
		--	sold_cumulat_valuta, ordonare, f.indicator indicator,
		--	rtrim(t.grupa) as gtert, rtrim(g.denumire) dengtert, rtrim(l.denumire) as denlm,
		--	rtrim(t.grupa) as grupa, rtrim(i.descriere) as den_pctlivrare, grupare1, denumire1,
		--	grupare2, denumire2
		--	, f.categ_yso, f.ord_categ_yso
		--from #fisa f left join terti t on t.subunitate=f.subunitate and f.tert=t.tert
		--	left join gterti g on t.grupa=g.grupa
		--	left join lm l on f.loc_de_munca=l.cod
		--	left join infotert i on i.subunitate=t.subunitate and i.tert=f.tert and i.identificator=f.nr_dvi
		--where f.cont_coresp like '472%' --*/
		)
		SELECT * 
		FROM (SELECT *, total AS total_pivot, achitat AS achitat_pivot, RTRIM(categ_yso)+'_total' AS categ_pivot_total, RTRIM(categ_yso)+'_achitat' AS categ_pivot_achitat
			FROM fisa) AS F
		PIVOT 
			(SUM(total_pivot) FOR categ_pivot_total IN 
				(
				"Facturi_avans_informativ_total",
				"Avize_nefacturate_avans_informativ_total",
				"Facturi_marfa_total",
				"Avize_nefacturate_marfa_total",
				"Facturi_servicii_total",
				"Avize_nefacturate_servicii_total",
				"Intocmiri_facturi_avize_nefacturate_total",
				"Bonuri_avans_informativ_total",
				"Bonuri_marfa_total",
				"Bonuri_servicii_total",
				"Incasari_total",
				"Instrumente_incasare_total",
				"Compensari_total",
				"Alte_operatii_total"
				)) AS P1
		PIVOT 
			(SUM(achitat_pivot) FOR categ_pivot_achitat IN 
				(
				"Facturi_avans_informativ_achitat",
				"Avize_nefacturate_avans_informativ_achitat",
				"Facturi_marfa_achitat",
				"Avize_nefacturate_marfa_achitat",
				"Facturi_servicii_achitat",
				"Avize_nefacturate_servicii_achitat",
				"Intocmiri_facturi_avize_nefacturate_achitat",
				"Bonuri_avans_informativ_achitat",
				"Bonuri_marfa_achitat",
				"Bonuri_servicii_achitat",
				"Incasari_achitat",
				"Instrumente_incasare_achitat",
				"Compensari_achitat",
				"Alte_operatii_achitat"
				)) AS P2

end try
begin catch
	set @q_eroare=ERROR_MESSAGE()+' (yso_rapFisaTerti_v01)'
end catch
	
IF OBJECT_ID('tempdb..#fisa') IS NOT NULL and @q_denesters=0 drop table #fisa
IF OBJECT_ID('tempdb..#fFacturi') IS NOT NULL drop table #fFacturi
IF OBJECT_ID('tempdb..#raport') IS NOT NULL drop table #raport
IF OBJECT_ID('tempdb..#facturiCuGestiuni') IS NOT NULL drop table #facturiCuGestiuni
IF OBJECT_ID('tempdb..#ctdocfarafact') IS NOT NULL drop table #ctdocfarafact
IF OBJECT_ID('tempdb..#test') IS NOT NULL drop table #test

	--> erorile in reporting nu apar, asa ca se vor returna ca date, urmand ca in raport sa se trateze situatia:
if (@q_eroare<>'')
	select '<EROARE>' as tert, @q_eroare as denumire
end