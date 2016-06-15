--***
CREATE procedure yso_rapFisaTerti(@cFurnBenef varchar(1),@cData datetime,@cTert varchar(50),@cFactura varchar(50),@cContTert varchar(50),
	@soldmin decimal(20,2),@soldabs int,@dDataFactJos datetime,@dDataFactSus datetime,@dDataScadJos datetime,@dDataScadSus datetime,
	@aviz_nefac int = 0,@grupa varchar(50) = null,@grupa_strict int, @exc_grupa varchar(50)=null,
	@fsolddata1 int, @fsold int=2,	--> @fsold=facturi pe sold; echivalenta cu : 1 => @soldmin=0.01 si @soldabs=1; 0 => @soldmin=0.00 si @soldabs=1
	@comanda varchar(50) = null,@indicator varchar(50) = null, @cDataJos datetime = null, 
	@tipdoc varchar(1) = 'F',	-->	sursa:	F=Facturi, E=Efecte, X=Toate
	@locm varchar(20) = null,
	@punctLivrare varchar(20) = null,
	@moneda bit=0, @valuta varchar(20)=null,
	@centralizare int=0,	--> prin parametrul centralizare se determina ordonarea datelor; daca 0=facturi se ord pe facturi, daca 1=documente se ord pe documente
	@gestiune varchar(20)=null)
as--*/
begin
/*	--	Valori pentru teste
declare @cFurnBenef nvarchar(1),@cData datetime,@cTert nvarchar(11),@cFactura nvarchar(4000),@cContTert nvarchar(4000),@soldmin nvarchar(4),@soldabs int,@dDataFactJos nvarchar(4000),@dDataFactSus nvarchar(4000),@dDataScadJos nvarchar(4000),@dDataScadSus nvarchar(4000),@aviz_nefac nvarchar(1),@grupa nvarchar(4000),@grupa_strict nvarchar(1),@exc_grupa nvarchar(4000),@fsolddata1 bit,@comanda nvarchar(4000),@indicator nvarchar(4000),@cDataJos datetime,@tipdoc nvarchar(1),@locm nvarchar(4000),@punctLivrare nvarchar(4000),@fsold bit,@moneda nvarchar(1),@valuta nvarchar(4000),@centralizare nvarchar(1),@gestiune nvarchar(4000)

select	@cFurnBenef=N'B',@cData='2013-02-12 00:00:00',@cTert=N'RO14257471',@cFactura=NULL,@cContTert=NULL,@soldmin=N'0.01',@soldabs=0,@dDataFactJos=NULL,@dDataFactSus=NULL,@dDataScadJos=NULL,@dDataScadSus=NULL,@aviz_nefac=N'0',@grupa=NULL,@grupa_strict=N'0',@exc_grupa=NULL,@fsolddata1=0,@comanda=NULL,@indicator=NULL,@cDataJos='2012-01-01 00:00:00',@tipdoc=N'F',@locm=NULL,@punctLivrare=NULL,@fsold=0,@moneda=N'0',@valuta=NULL,@centralizare=N'0',@gestiune=NULL
--*/
	set transaction isolation level read uncommitted
	if object_Id('tempdb.dbo.#ftert') is not null drop table #ftert
	IF OBJECT_ID('tempdb..#raport') IS NOT NULL drop table #raport
	IF OBJECT_ID('tempdb..#facturiCuGestiuni') IS NOT NULL drop table #facturiCuGestiuni
declare @eroare varchar(1000)
set @eroare=''
begin try
	if (@fsold=1)	select @soldmin=0.01, @soldabs=0
	if (@fsold=0)	select @soldmin=0.00, @soldabs=0
	declare @utilizator varchar(50)
--	exec wIaUtilizator @sesiune='', @utilizator=@utilizator output
	declare @cuFltLocmStilVechi int, @fltLocmStilNou varchar(20)	--> se alege tipul filtrarii pe loc de munca in functie de setare
	select @cuFltLocmStilVechi=0, @fltLocmStilNou=@locm
	if exists (select 1 from par where Tip_parametru='GE' and Parametru='FLTTRTLM' and Val_logica=1)
		select @cuFltLocmStilVechi=1, @fltLocmStilNou=null
	
	declare @dataImplementarii datetime,
			@dataSolduri datetime		/**	data pana la care orice sume vor aparea ca solduri	*/
	select @dataImplementarii=--'1921-1-1'
	dateadd(d,-1,
		dateadd(m,1,
		isnull((select convert(varchar(4),val_numerica) from par where tip_parametru='ge' and parametru='ANULIMPL'),'1921')+'-'+
		isnull((select convert(varchar(2),val_numerica) from par where tip_parametru='ge' and parametru='lunaimpl'),'1')+'-1'
		)),
		@dataSolduri=convert(datetime,convert(varchar(4),year(@cData))+'-1-1')
		if (@dataSolduri<@dataImplementarii)
		
			set @dataSolduri=@dataImplementarii
	--*/
	declare @soldmin_f varchar(20), @tipef varchar(1)
	select @soldmin_f='0.00',
		@tipef=(case when @cFurnBenef='F' then 'P' else 'I' end)
	
	declare @avemDataJos int	select @avemDataJos=1
	if (@cDataJos is null)
	begin
		set @cDataJos='1921-1-1'
		--set @fsolddata1=0
		set @avemDataJos=0
		--set @soldmin_f=@soldmin
	end
	set @cDataJos=dateadd(d,-1,@cDataJos)
	if(@cDataJos<@dataSolduri and @avemDataJos=0)
	begin
			 -- set @soldmin_f=@soldmin
			  set @cDataJos=@dataSolduri
	end
	
	if (isnull(@cFurnBenef,'')<>'B' or @cTert is null) set @punctLivrare=null /** filtru pe punct livrare doar daca s-a filtrat pe un beneficiar*/
	
	declare @q_comanda varchar(40)
	set @q_comanda=	isnull(@comanda,'')+space(20-LEN(isnull(@comanda,'')))+
					isnull(@indicator,'')+space(20-LEN(isnull(@indicator,'')))
	/**1.	Creare tabela temporara - pentru a se aranja mai usor datele in forma necesara raportului:*/
		create table #ftert(
			sursa varchar(1), furn_benef varchar(1), subunitate varchar(20), tert varchar(50),
			factura varchar(50), tip varchar(10), numar varchar(20), data datetime, 
			valoare decimal(20,3), tva decimal(20,3), achitat decimal(20,3), valuta varchar(10),
			curs decimal(20,3), total_valuta decimal(20,3), achitat_valuta decimal(20,3),
			loc_de_munca varchar(50), comanda varchar(50), cont_de_tert varchar(50), fel int,
			cont_coresp varchar(50), gestiune varchar(50), data_facturii datetime, 
			data_scadentei datetime, nr_dvi varchar(50), barcod varchar(50), explicatii varchar(500),
			data_platii datetime, numar_pozitie int, pozitie int
			)

if (@tipdoc='X' or @tipdoc='F')
		insert into #ftert(sursa, furn_benef, subunitate, tert, factura, tip, numar, data, valoare, tva,
				achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
				fel, cont_coresp, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, explicatii,
				data_platii, numar_pozitie, pozitie)
		select 'F' sursa,
		ft.furn_benef furn_benef, ft.subunitate subunitate, ft.tert, ft.factura,  
		tip, ft.numar,  ft.data data, ft.valoare valoare, ft.tva, ft.achitat, ft.valuta valuta,
		ft.curs curs, ft.total_valuta total_valuta, ft.achitat_valuta achitat_valuta, ft.loc_de_munca loc_de_munca, 
		ft.comanda comanda, ft.cont_de_tert cont_de_tert, ft.fel fel, ft.cont_coresp cont_coresp,
		ft.gestiune gestiune, 
		ft.data_facturii as data_facturii, 
		isnull(ft.data_scadentei, ft.data_scadentei) as data_scadentei, 
		ft.nr_dvi nr_dvi, ft.barcod barcod, explicatii, data_platii, numar_pozitie, pozitie
		from dbo.fTert (@cFurnBenef, @cDataJos, @cData,@cTert,@cFactura,@cContTert,@soldmin_f,0,0,@fltLocmStilNou) ft
		where --(@tipdoc='X' or @tipdoc='F') and
			ft.data_scadentei between isnull(@dDataScadJos,'1901-1-1') and isnull(@dDataScadSus,'2999-1-1')
			and (@aviz_nefac=0 or rtrim(isnull(ft.factura,''))<>'')
			and (@comanda is null or left(ft.comanda,20)=@comanda) and (@indicator is null or substring(ft.comanda,21,20)=@indicator)
			and (@punctLivrare is null or ft.nr_dvi=@punctLivrare)

if (@tipdoc='X' or @tipdoc='E')
		insert into #ftert(sursa, furn_benef, subunitate, tert, factura, tip, numar, data, valoare, tva,
				achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, comanda, cont_de_tert,
				fel, cont_coresp, gestiune, data_facturii, data_scadentei, nr_dvi, barcod, explicatii,
				data_platii, numar_pozitie, pozitie)
		select 'E' sursa,
		(case when ft.tip_efect='P' then 'F' else 'B' end) furn_benef, ft.subunitate subunitate, ft.tert, ft.factura,
		ft.tip_efect tip, ft.numar_document,  ft.data data, ft.valoare valoare, 0 tva, ft.achitat, ft.valuta valuta,
		ft.curs curs, ft.valoare_valuta total_valuta, ft.achitat_valuta achitat_valuta, ft.loc_de_munca loc_de_munca, 
		ft.comanda comanda, ft.cont cont_de_tert, '' fel, ft.cont_corespondent cont_coresp,
		'' gestiune, ft.data as data_facturii, 
		isnull(ft.data_scadentei, ft.data_scadentei) as data_scadentei, 
		'' nr_dvi, '' barcod, explicatii, '1901-1-1', numar_pozitie, ''
		from dbo.fEfecte(@cDataJos, @cData,@tipef,@cTert,@cFactura,@cContTert,'','',NULL) ft
		where --@cDataJos>dateadd(d,-1,@dataSolduri)
			(@tipdoc='X' or @tipdoc='E')
			and isnull(ft.data_scadentei, ft.data_scadentei) 
					between isnull(@dDataScadJos,'1901-1-1') and isnull(@dDataScadSus,'2999-1-1')
			and (@aviz_nefac=0 or rtrim(isnull(ft.factura,''))<>'')
			and (@comanda is null or left(ft.comanda,20)=@comanda) 
				and (@indicator is null or substring(ft.comanda,21,20)=@indicator)
		--test select * from #ftert

	delete t from #ftert t where
	isnull((select (case when @soldabs=1 then sum(valoare+tva-achitat) 
						else abs(sum(valoare+tva-achitat)) end) from #ftert f 
		where t.tert=f.tert and t.factura=f.factura and t.sursa=f.sursa --and f.data>@cDataJos
	),0)<@soldmin --and @fsolddata1=0	/**	Se elimina facturile/efectele al caror sold final este mai mic decat @soldmin*/
	--select * into #test from #ftert
	/**2.	Aranjarea datelor pentru raport:*/
	if (@avemDataJos=1) set @cDataJos=dateadd(d,1,@cDataJos)
	
	create table #facturiCuGestiuni(tert varchar(20), factura varchar(20))
	if (@gestiune is not null)
	begin
		insert into #facturiCuGestiuni (tert, factura)
		select tert, factura from #ftert where gestiune=@gestiune and isnull(factura,'')<>'' group by tert, factura
	
		delete f
		from #ftert f where not exists (select 1 from #facturiCuGestiuni g where g.tert=f.tert and g.factura=f.factura)
	end
--select * from #ftert
	select sursa,
	t.denumire, l.oras, 
	furn_benef, f.subunitate, f.tert, f.factura, tip, numar, data, soldi, soldi_valuta, valoare,
	tva, achitat, valuta, curs, total_valuta, achitat_valuta, 
	loc_de_munca, comanda, cont_de_tert, fel, cont_coresp, explicatii, numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi, 
	barcod, pozitie, peSold, row_number() over (partition by /*sp tip, sp*/ f.subunitate, f.factura, f.tert, f.sursa, f.furn_benef order by f.data_facturii /*sp desc sp*/, f.data_scadentei /*sp desc sp*/) as primSold,
	space(200) as ordonare, convert(decimal(15,3),0) as sold_cumulat,
	rtrim(isnull(f.tert,''))+'|'+(case when @moneda=0 then '' else isnull(f.valuta,'') end)
		as partitionareSold
	into #raport
	from
	(	/**	Sold initial */
		select sursa,
			furn_benef, subunitate, tert, factura, 
			'SI' tip, factura numar, min(data) as data, sum(round(valoare+tva-achitat,2)) as soldi,
			sum(round(f.total_valuta-achitat_valuta,2)) as soldi_valuta, 0 as valoare,
			0 tva, 0 achitat, max(valuta) valuta, max(curs) curs, 0 total_valuta,
			0 achitat_valuta,
			max(loc_de_munca) loc_de_munca, max(comanda) comanda, max(cont_de_tert) cont_de_tert, max(fel) fel, max(cont_coresp) cont_coresp, 
			'sold initial' explicatii, 0 numar_pozitie, max(gestiune) gestiune, /*sp max sp*/min(data_facturii) data_facturii,
			/*sp max sp*/min(data_scadentei) data_scadentei, max(nr_dvi) nr_dvi, max(barcod) barcod, 0 pozitie,
			(case when abs(sum(round(valoare+tva-achitat,2)))>0.0001 then 1 else 0 end) as peSold
		from #ftert f
		where	--(@fsolddata1=0 or abs(valoare)>0.0001) and 
			f.data<@cDataJos
		group by subunitate, factura,tert, --f.data,
			sursa, furn_benef
	union all	/**	rulaje	*/
		select sursa, furn_benef, subunitate, tert, factura, tip, numar, data, 
			0 as soldi, 0 as soldi_valuta, round(valoare,2),	round(tva,2), round(achitat,2), 
			valuta, curs, total_valuta, achitat_valuta, 
			loc_de_munca, comanda, cont_de_tert, fel, cont_coresp, 
			(case when f.tip='IB' and f.data_platii<>f.data	then convert(varchar(20),f.data_platii,103) else '' end)+' '+
			rtrim(explicatii), numar_pozitie, gestiune, data_facturii, data_scadentei, nr_dvi, 
			barcod, pozitie, 0 as peSold
		from #fTert f
			where --(@tipdoc='X' or @tipdoc='F') and	--< pe efecte nu se iau rulaje?
				f.data>=@cDataJos
	) f
		left outer join terti t on f.tert=t.tert and f.subunitate=t.subunitate
		left outer join localitati l on t.localitate=l.cod_oras
		where ((@grupa is null and @grupa_strict in (0,1)) or (@grupa_strict = 0 and @grupa is not null and t.grupa like rtrim(@grupa)+'%') or 
				(@grupa_strict = 1 and @grupa is not null and t.grupa = rtrim(@grupa)))
				and (@exc_grupa is null or t.grupa <> @exc_grupa) and (@cuFltLocmStilVechi=0 or @locm is null or f.loc_de_munca like @locm+'%')
	order by f.tert, (case when @moneda=0 then '' else f.valuta end), f.data, f.tip, f.numar

	create index indrap on #raport (subunitate, factura, tert, data, sursa, furn_benef)
	
	--> eliminare inregistrari care nu au sold initial, daca se doreste doar facturi pe sold la inecput interval:
	if (@fsolddata1=1)
	delete r from #raport r where not exists (select 1 from #raport rs where rs.tip='SI' and
			rs.subunitate=r.subunitate and rs.factura=r.factura and rs.tert=r.tert --and rs.data_facturii=r.data_facturii
			and rs.sursa=r.sursa and rs.furn_benef=r.furn_benef		-->>????? trebuie join pe data, si daca da, cum?
			and rs.data<@cDataJos)
	
	--> eliminare inregistrari care au fost achitate complet inainte de inceputul intervalului:
	delete r from #raport r where exists (select 1 from #raport rs where rs.tip='SI' and
			rs.subunitate=r.subunitate and rs.factura=r.factura and rs.tert=r.tert --and rs.data_facturii=r.data_facturii
			and rs.sursa=r.sursa and rs.furn_benef=r.furn_benef
			and rs.peSold=0)

	--> eliminare inregistrari care nu se incadreaza in intervalul datei emiterii:
	delete f from #raport f where exists (select 1 from #raport f1 where f1.tert=f.tert and f1.factura=f.factura and
			((f1.valoare<>0 or f1.soldi<>0)
			and not isnull(f1.data,f1.data_facturii) between isnull(@dDataFactJos,'1901-1-1') and isnull(@dDataFactSus,'2999-1-1'))
			)

--/*	--> stabilesc data facturii si data scadentei pentru toate liniile care tin de o factura:
--select * from #raport
	update r set data_facturii=rs.data_facturii, data_scadentei=rs.data_scadentei
	from #raport r inner join #raport rs on /*sp rs.tip='SI' and */
			rs.subunitate=r.subunitate and rs.factura=r.factura and rs.tert=r.tert
			and rs.sursa=r.sursa and rs.furn_benef=r.furn_benef and rs.primSold=1
		--*/
select * from #raport
	declare @partitionareSold varchar(100), @soldC decimal(15,3)
	select @partitionareSold='', @soldC=0
	update #raport set ordonare=(case
			when @centralizare=0 then rtrim(tert)+'|'+convert(varchar(20), data_facturii,102)+'|'
					+rtrim(factura)+'|'+convert(varchar(20), data,102)
			when @moneda=0 then rtrim(tert)+'|'+convert(varchar(20), data,102)+'|'+rtrim(tip)+'|'
					+rtrim(numar)
			else rtrim(tert)+'|'+rtrim(valuta)+'|'+convert(varchar(20), data,102)+'|'+rtrim(tip)+'|'
					+rtrim(numar) end),
					@soldc=(case when @partitionareSold=partitionareSold then @soldc
								else 0 end)+
							(case when @moneda=0 then isnull(soldi,0)+isnull(valoare,0)+
										isnull(tva,0)-isnull(achitat,0)
									else isnull(soldi_valuta,0)+isnull(total_valuta,0)-
										isnull(achitat_valuta,0)
							end),
					sold_cumulat=@soldc,
					@partitionareSold=partitionareSold

	if @moneda=0	--> in lei:
	select sursa,
		denumire, oras, furn_benef, subunitate, tert, factura, tip, rtrim(numar) numar, data,
		soldi, valoare, tva, achitat, valuta, curs, total_valuta, achitat_valuta, loc_de_munca, 
		comanda, cont_de_tert, fel, cont_coresp, rtrim(explicatii) explicatii, numar_pozitie,
		gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, sold_cumulat
	from #raport
	order by ordonare

	if @moneda=1	-->	in valuta:
	select sursa,
		denumire, oras, furn_benef, subunitate, tert, factura, tip, rtrim(numar) numar, data,
		soldi_valuta soldi, total_valuta valoare, 0 tva, achitat_valuta achitat, valuta, curs,
		total_valuta, achitat_valuta, loc_de_munca, 
		comanda, cont_de_tert, fel, cont_coresp, rtrim(explicatii) explicatii, numar_pozitie,
		gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, sold_cumulat
	from #raport where len(rtrim(valuta))>0 and (@valuta is null or valuta=@valuta)
	order by ordonare
end try
begin catch
	set @eroare='yso_rapFisaTerti (linia '+convert(varchar(20),ERROR_LINE())+') '+char(10)+
				ERROR_MESSAGE()
end catch
/*	
IF OBJECT_ID('tempdb..#ftert') IS NOT NULL drop table #ftert
IF OBJECT_ID('tempdb..#raport') IS NOT NULL drop table #raport
IF OBJECT_ID('tempdb..#facturiCuGestiuni') IS NOT NULL drop table #facturiCuGestiuni
*/
if (@eroare<>'')
	raiserror(@eroare,16,1)
end
