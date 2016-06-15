--***
create procedure yso_rapFisaConturiTert(@sesiune varchar(50)=null, @cFurnBenef varchar(1),@cDataJos datetime,@cDataSus datetime,@cTert varchar(50)=null
	,@cContTert varchar(40),
	@grupa varchar(50)=null,
	@exc_grupa varchar(50)=null, @cFactura varchar(40)=null, @grfact varchar(40)=null, @lm varchar(40) = null, @comanda varchar(40) = null,
	@cont_cor varchar(40) = null, @tipinc varchar(40) = null,@indicator varchar(40)=null,@detTVA varchar(1)='1',
	@ordonare int	--> 0=cod tert, 1=denumire tert
	)
	--, @tip_platitor int =0)
as 
-- @tip_platitor reprezinta "tip platitor TVA", are valorile: 0=toti tertii, 1=doar platitorii, 2=doar neplatitorii 
declare @eroare varchar(2000)
set @eroare=''
begin try
	IF OBJECT_ID('tempdb..#fFactura') IS NOT NULL drop table #fFactura
	IF OBJECT_ID('tempdb..#cuzero') IS NOT NULL drop table #cuzero
	IF OBJECT_ID('tempdb..#date') IS NOT NULL drop table #date
	declare @utilizator varchar(50)
--	exec wIaUtilizator @sesiune='', @utilizator=@utilizator output
	declare @parXML xml, @parXMLFact xml
	select @parXML=(select @sesiune as sesiune for xml raw)
	/* Am scos cele de mai jos pentru ca fFacturi aduce datele filtrate in functie de setare, nu este nevoie sa se trateze aici
	declare @cuFltLocmStilVechi int, @fltLocmStilNou varchar(20)	--> se alege tipul filtrarii pe loc de munca in functie de setare
	select @cuFltLocmStilVechi=0, @fltLocmStilNou=@lm 
	if exists (select 1 from par where Tip_parametru='GE' and Parametru='FLTTRTLM' and Val_logica=1)
		select @cuFltLocmStilVechi=1, @fltLocmStilNou=null
	*/	

/*
select	@cFurnBenef=N'F',@cDataJos='2010-01-01 00:00:00',@cDataSus='2010-01-31 00:00:00',@cTert=N'1185',@cContTert=N'4091',@grupa=NULL,
		@exc_grupa=NULL,@cFactura=NULL,@grfact=NULL,@lm=NULL,@comanda=NULL,@cont_cor=NULL,@tipinc=NULL,
		@indicator=NULL,@detTVA=N'1'
*/	set transaction isolation level read uncommitted
	declare @epsilon decimal(6,5), @dataAnt datetime
			/**	@epsilon = marja de eroare pentru valorile numerice
				@dataAnt = data anterioara intervalului trimis din raport
			*/
		set @dataAnt=DateAdd(d,-1,@cDataJos)
	set @epsilon=0.0001
/**1.	creare cursor pentru a imparti datele mai usor si mai rapid in continuare pe sold si pe rulaj*/
	/* se preiau datele in tabela #docfacturi prin procedura pFacturi (in locul functiei fFacturi) */
	if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
	create table #docfacturi (furn_benef char(1))
	exec CreazaDiezFacturi @numeTabela='#docfacturi'
	set @parXMLFact=(select @cFurnBenef as furnbenef, convert(char(10),@cDataJos,101) as datajos, convert(char(10),@cDataSus,101) as datasus, 
		rtrim(@cTert) as tert, rtrim(@cFactura) as factura, rtrim(@cContTert) as contfactura, @lm as locm, 1 as prelconttva,
		@indicator indicator for xml raw)
	exec pFacturi @sesiune=@sesiune, @parXML=@parXMLFact

	select
		t.denumire,t.grupa,ft.furn_benef, ft.subunitate, rtrim(ft.tert) tert, ft.factura, ft.tip, ft.numar, ft.data,
		ft.valoare valoare, ft.tva tva,
		ft.achitat achitat, ft.valuta, ft.curs, 
		ft.total_valuta total_valuta, ft.achitat_valuta achitat_valuta,
		ft.loc_de_munca, 
		isnull(f.comanda,ft.comanda) as comanda,
		ft.cont_de_tert, ft.fel, ft.cont_coresp, ft.explicatii, ft.numar_pozitie,
		ft.gestiune,
		isnull(f.data,ft.data_facturii) as data_facturii,	isnull(f.data_scadentei, ft.data_scadentei) as data_scadentei,
		ft.nr_dvi, ft.barcod, ft.pozitie, ft.contTVA,
		row_number() over (partition by ft.tert, year(ft.data), month(ft.data) 
		order by
			f.data, 
			ft.data_facturii, ft.factura,ft.furn_benef,ft.tip,ft.numar, ft.numar_pozitie) as nr_pe_luna_asc,
		1 as inversare	--> -1= e nevoie de inversare, 1=e bine
		,suma=ft.Valoare+ft.Achitat
	into #fFactura
	from #docfacturi ft
		left outer join facturi f on f.subunitate=ft.subunitate and f.tert=ft.tert and f.factura=ft.factura and ft.furn_benef=(case when f.tip=0x54 then 'F' else 'B' end)
		left outer join terti t on ft.tert=t.tert and ft.subunitate=t.subunitate
	where 
		(@grupa is null or t.grupa like rtrim(@grupa)+'%') and (@exc_grupa is null or t.grupa <> @exc_grupa)
		and (@cFactura is null or ft.factura = rtrim(@cFactura))
		and (@grfact is null or ft.factura like rtrim(@grfact)+'%')
		and (@comanda is null or rtrim(substring(ft.comanda,1,20))= rtrim(@comanda))
		and (@cont_cor is null or rtrim(ft.cont_coresp) like rtrim(@cont_cor)+'%')
		and (@tipinc is null or exists (select nr_doc from incfact e 
			where ft.subunitate=e.subunitate and ft.tert=e.tert and ft.factura=e.numar_factura 
		and e.mod_plata=@tipinc))

	if @cont_cor is not null -- daca se filtreaza pe cont corespondent se asunde TVA-ul
		update #fFactura set tva=0

	-- stabilirea inversarii inregistrarilor 
	update #fFactura set inversare=-1 
		where (@cFurnBenef='F' and (cont_coresp like '7%' or cont_coresp like '6%' and exists (select 1 from conturi where cont=cont_coresp and Tip_cont='P'))
				or @cFurnBenef='B' and (cont_coresp like '6%' or cont_coresp like '7%' and exists (select 1 from conturi where cont=cont_coresp and Tip_cont='A')))
			and valoare<>0 and achitat=0

	update #fFactura set inversare=-2 
		where (@cFurnBenef='F' and left(cont_coresp,1) in ('6','7') and exists (select 1 from conturi where cont=cont_coresp and Tip_cont='A')
				or @cFurnBenef='B' and exists (select 1 from conturi where cont=cont_coresp and Tip_cont='P'))
			and valoare=0 and achitat<>0 and not (tip in ('CO','C3') and @cFurnBenef='B')

	--select * from #fFactura
	create index indx_ftert on #fFactura(data, tert, tip)
--test	select SUM(valoare), SUM(tva) from #fFactura
/**2.	se creeaza tabela cu datele organizate pentru a se putea afisa in raport; se foloseste inca o tabela pentru a se mai putea filtra 
		datele inainte de a le trimite */
	
	create table #date(denumire varchar(200), grupa varchar(20), nrpoz varchar(20), cont_corespondent varchar(40), debitare varchar(1), 
		soldfactbenef decimal(15,3), soldfactfurn decimal(15,3), furn_benef varchar(1), subunitate varchar(10), tert varchar(20), factura varchar(20),
		tip varchar(2), numar varchar(20), data datetime, valoare decimal(15,3), tva decimal(15,3), achitat decimal(15,3), valuta varchar(3),
		curs decimal(15,3), total_valuta decimal(15,3), achitat_valuta decimal(15,3), loc_de_munca varchar(20), comanda varchar(40),
		cont_de_tert varchar(40), fel int, cont_coresp varchar(40), explicatii varchar(200), numar_pozitie int, gestiune varchar(20),
		data_facturii datetime, data_scadentei datetime, nr_dvi varchar(20), barcod varchar(30), pozitie int, ordonare varchar(500),
		sold_initial_luna decimal(15,3) default 0, sold_final_luna decimal(15,3) default 0, nr_pe_luna_asc int default 0, nr_pe_luna_desc int default 0,
		inversare int
		, suma decimal(15,3))
	--> reorganizarea datelor luate cu fFactura:
	/**	rulaj valoare	*/
	insert into #date(denumire, grupa, nrpoz, cont_corespondent, debitare, soldfactbenef, soldfactfurn, furn_benef, subunitate, tert,
		factura, tip, numar, data, valoare, tva, achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
		fel, cont_coresp, explicatii, numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, ordonare, nr_pe_luna_asc, inversare
		,suma)
	select ft.denumire,ft.grupa,'' as nrpoz, ft.cont_coresp as cont_corespondent,
		(case when left(ft.tip,1)='P' or (ft.tip='SI' and furn_benef='B') or 
		(furn_benef='F' and ft.tip in ('SX', 'CO', 'FX', 'C3', 'RX')) or 
		(furn_benef<>'F' and ft.tip not in ('SI', 'IB', 'IR','IX', 'BX', 'CO', 'C3', 'AX'))
		or (ft.tip in ('SI', 'IB', 'IR') and furn_benef='F') 
		or (ft.tip in ('SI', 'PF', 'PR') and furn_benef='B')  then 'D' else 'C' end) as debitare,
		0 as soldfactbenef, 0 as soldfactfurn, 
		ft.furn_benef, ft.subunitate, ft.tert, ft.factura, ft.tip, ft.numar, ft.data, ft.valoare, 0 tva, ft.achitat, ft.valuta, ft.curs, ft.total_valuta,
		ft.achitat_valuta, ft.loc_de_munca, ft.comanda, ft.cont_de_tert,
		ft.fel, ft.cont_coresp, ft.explicatii, ft.numar_pozitie, ft.gestiune,
		ft.data_facturii, ft.data_scadentei, ft.nr_dvi, ft.barcod, ft.pozitie, (case when @ordonare=0 then ft.tert else ft.denumire end) ordonare,
		ft.nr_pe_luna_asc*2-1, inversare
		,ft.suma
		--(ft.nr_pe_luna_desc+1)*2-1
	from #fFactura ft 
	where ft.data>@dataAnt
	
	-- aplicarea inversarii inregistrarilor 
	update #date set 
			--cont_corespondent=cont_de_tert, 
			--cont_de_tert=cont_coresp,
			achitat=-1*valoare, 
			valoare=0, 
			debitare=(case when debitare='C' then 'D' else 'C' end) 
		where inversare=-1

	update #date set 
			--cont_corespondent=cont_de_tert, 
			--cont_de_tert=cont_coresp,
			valoare=-1*achitat, 
			achitat=0, 
			debitare=(case when debitare='C' then 'D' else 'C' end) 
		where inversare=-2

	/**	rulaj tva		*/
	insert into #date(denumire, grupa, nrpoz, cont_corespondent, debitare, soldfactbenef, soldfactfurn, furn_benef, subunitate, tert,
		factura, tip, numar, data, valoare, tva, achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
		fel, cont_coresp, explicatii, numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, ordonare, nr_pe_luna_asc,
		inversare
		,suma)
	select ft.denumire,ft.grupa,(case when @detTVA=1 then '1' else '' end) nrpoz, 
		--(case when furn_benef='F' then '4426' else '4427' end)
		ft.contTVA,
		(case when left(ft.tip,1)='P' or (ft.tip='SI' and furn_benef='B') or 
		(furn_benef='F' and ft.tip in ('SX', 'CO', 'FX', 'C3', 'RX')) or 
		(furn_benef<>'F' and ft.tip not in ('SI', 'IB', 'IR','IX', 'BX', 'CO', 'C3', 'AX'))
		or (ft.tip in ('SI', 'IB', 'IR') and furn_benef='F') 
		or (ft.tip in ('SI', 'PF', 'PR') and furn_benef='B')  then 'D' else 'C' end) as debitare,
		0 as soldfactbenef, 0 as soldfactfurn, 
		ft.furn_benef, ft.subunitate, ft.tert, ft.factura, ft.tip, ft.numar, ft.data, 0 valoare, ft.tva, 0 achitat, ft.valuta, 
		ft.curs,0 total_valuta, 0 achitat_valuta, ft.loc_de_munca, ft.comanda, ft.cont_de_tert, ft.fel, ft.cont_coresp, 
			'<TVA> '+ft.explicatii, ft.numar_pozitie, ft.gestiune, ft.data_facturii, ft.data_scadentei, ft.nr_dvi, ft.barcod, ft.pozitie,
		(case when @ordonare=0 then ft.tert else ft.denumire end) ordonare, nr_pe_luna_asc*2, 1 inversare
		,ft.suma
	from #fFactura ft
	where tva<>0 and ft.data>@dataAnt
--test	select tert, data, nr_pe_luna_asc from #date order by tert,data,nr_pe_luna_asc
	/**	sold	*/
	insert into #date(denumire, grupa, nrpoz, cont_corespondent, debitare, soldfactbenef, soldfactfurn, furn_benef, subunitate, tert,
		factura, tip, numar, data, valoare, tva, achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
		fel, cont_coresp, explicatii, numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, ordonare, inversare
		, suma)
	select max(ft.denumire),max(ft.grupa),'' nrpoz, '' contTVA,
		max( case when ft.tip='B'  then 'D' else 'C' end) as debitare,
		(case when @cFurnBenef='B' then sum(ft.valoare+ft.tva-achitat) else 0 end) soldfactbenef,
		(case when @cFurnBenef='F' then sum(ft.valoare+ft.tva-achitat) else 0 end) soldfactfurn,
		'S', '', ft.tert, ft.factura, '','',max(ft.data),
		0,0,0,'',0,0,0,'','','',0,'','',0,'',max(ft.data_facturii),'1901-1-1','','',0,
		max(case when @ordonare=0 then ft.tert else ft.denumire end) ordonare, 1 inversare
		,ft.suma
		/*,max(nr_pe_luna_asc)*3*/
		--'','','','','','','','','','','','','','','','','','','',''
	from #fFactura ft
	where /*tva<>0
		and*/ ft.data<=@dataAnt
	group by ft.tert, ft.factura

	create clustered index date_ordine on #date(tert, data, nr_pe_luna_asc)

	--> se calculeaza soldul pentru detalierea pe luni (in loc de detalierea pe facturi):
	declare @sold_final_luna decimal(15,3), @tert varchar(200)
	select @sold_final_luna=0, @tert=''	--sum(d.soldfactbenef-d.soldfactfurn) from #date d where d.data<=@dataAnt

	update d set @sold_final_luna=(case when @tert<>d.tert then 0 else @sold_final_luna end),
			sold_final_luna=@sold_final_luna,
			sold_initial_luna=@sold_final_luna-(d.soldfactbenef+d.soldfactfurn+valoare+tva-achitat),
			@sold_final_luna=d.soldfactbenef+d.soldfactfurn+valoare+tva-achitat+@sold_final_luna, @tert=d.tert
			--,nr_pe_luna_desc=nr_pe_luna_desc*2-nr_pe_luna_asc
	from #date d

	update d set d.sold_initial_luna=da.sold_initial_luna
	from #date d, #date da where da.nr_pe_luna_asc=1 and da.tert=d.tert and month(d.data)=month(da.data) and year(d.data)=year(da.data)

	update d set d.nr_pe_luna_desc=ft.nr_pe_luna_desc
	from #date d inner join
		(select tert,nr_pe_luna_asc, data,
		row_number() over (partition by ft.tert, year(ft.data), month(ft.data) order by /*year(ft.data), month(ft.data),*/	nr_pe_luna_asc desc) as nr_pe_luna_desc
		from #date ft) ft on d.tert=ft.tert and year(ft.data)=year(d.data) and month(ft.data)=month(d.data) and d.nr_pe_luna_asc=ft.nr_pe_luna_asc
	
	update d set d.sold_final_luna=da.sold_final_luna
	from #date d, #date da where da.nr_pe_luna_desc=1 and da.tert=d.tert and month(d.data)=month(da.data) and year(d.data)=year(da.data)
/*--test
	select d.data, d.nr_pe_luna_desc, d.nr_pe_luna_asc, d.sold_initial_luna, d.soldfactbenef, d.soldfactfurn, valoare, tva, achitat, d.sold_final_luna
	from #date d
		*/--*/--*/--*/--*/--*/--*/--*/
--/*
/**3.	se trimit datele la raport	*/
	select ordonare, rtrim(denumire) denumire, rtrim(grupa) grupa, rtrim(a.cont_de_tert) as cont_factura, rtrim(a.cont_coresp) as cont_coresp
		, isnull(c.tip_cont,'B') tip_cont,
		rtrim((case a.debitare when 'D' then cont_corespondent when 'C' then cont_de_tert end)) cont_corespondent, 
		debitare, soldfactbenef, soldfactfurn, rtrim(tert) tert, rtrim(factura) factura, rtrim(tip) tip, rtrim(numar) numar,
		data, (case when tip not in ('CF','CB','PS','IS') then valoare else -achitat end) valoare, tva, (case when tip not in ('CF','CB','PS','IS') then achitat else -valoare end) achitat, 
		rtrim(case a.debitare when 'D' then cont_de_tert when 'C' then cont_corespondent end) cont_de_tert,
		rtrim(explicatii) explicatii, numar_pozitie, data_facturii, data_scadentei, nrpoz, furn_benef, sold_initial_luna, sold_final_luna,
		a.ordonare, a.tert, a.data_facturii,a.factura,a.denumire,a.furn_benef,a.debitare,a.tip,a.numar, a.nrpoz, a.inversare
		, a.suma
	 from #date a
		left join conturi c on a.cont_de_tert=c.Cont
	 where tva<>0 or valoare<>0 or achitat<>0 or furn_benef='S'
		and abs(tva)>@epsilon or abs((case when tip not in ('CF','CB','PS','IS') then valoare else -achitat end))>@epsilon
				or abs(case when tip not in ('CF','CB','PS','IS') then achitat else -valoare end)>@epsilon
				or furn_benef='S' and (abs(a.soldfactbenef)>@epsilon or abs(a.soldfactfurn)>@epsilon)
	 order by a.ordonare, a.tert, a.data,a.factura,a.denumire,a.furn_benef,a.debitare,a.tip,a.numar, a.nrpoz, numar_pozitie
--*/
end try
begin catch
	set @eroare='yso_rapFisaConturiTert (linia '+convert(varchar(20),ERROR_LINE())+') '+char(10)+
				ERROR_MESSAGE()
end catch

IF OBJECT_ID('tempdb..#fFactura') IS NOT NULL drop table #fFactura
IF OBJECT_ID('tempdb..#cuzero') IS NOT NULL drop table #cuzero
IF OBJECT_ID('tempdb..#date') IS NOT NULL drop table #date
	select @eroare as denumire, '<EROARE>' as tert