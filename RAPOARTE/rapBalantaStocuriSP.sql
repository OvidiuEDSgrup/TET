/*	Procedura pt rapoartele de Balanta stocuri (web).	*/
--***
if exists (select 1 from sysobjects o where o.name='rapBalantaStocuriSP')
	drop procedure rapBalantaStocuriSP
GO
--***
create procedure rapBalantaStocuriSP(@dDataJos datetime, @dDataSus datetime,@cCod varchar(20), @cGestiune varchar(20), @cCodi varchar(20), @cCont varchar(20),
	@TipStocuri varchar(20), @den varchar(20), @gr_cod varchar(20), 
	@tip_pret varchar(1)=0,	-->	0=stoc, 1=amanuntul, 2=pe tip gestiune, 3=vanzare
	@tiprap varchar(20), @ordonare varchar(20)=0,	--> @ordonare=1 ordonare alfabetica pe nume produs, =0 ordonare pe cod produs
	@grupare4 bit=0,							--> grupare pe pret (0=nu, 1=da)
	@comanda varchar(200)=null,
	@centralizare int=3,	--> 0=grupare1, 1=grupare2, 2=cod, 3=fara centralizare
	@grupare int=0,	-->	0=Gestiuni si grupe, 1=Gestiuni si conturi, 3=Conturi si gestiuni, 4=Gestiuni si locatii, 5=Grupe (si nimic)
	@categpret smallint=null,
	@locatie varchar(30)=null,
	@furnizor_nomenclator varchar(20)=null
	)
as
	/*	test
	declare @dDataJos datetime, @dDataSus datetime,@cCod varchar(20), @cGestiune varchar(20), @cCodi varchar(20), @cCont varchar(20),
		@TipStocuri varchar(20), @den varchar(20), @gr_cod varchar(20), @tip_pret varchar(1), @tiprap varchar(20)
	select @dDataJos='2008-10-10', @dDataSus='2012-10-31',@cCod='122', @cGestiune=null, @cCodi=null, --@cCont='371', 
			@TipStocuri=''
		--@den='%', @gr_cod=null, 
		,@tip_pret='0'
		/*select * from tmpRefreshLuci where
	(@dDataJos='2008-1-1' and  @dDataSus='2009-10-1' and @cCod=null and  @cGestiune=null and  @cCodi=null and  @cCont=null and  @TipStocuri='M' and 
		@den='%' and  @gr_cod=null) or 1=1
		*/ -- select pentru refresh fields in Reporting, ca sa nu se incurce in tabela #stocuri
	--*/
set transaction isolation level read uncommitted
declare @q_dDataJos datetime, @q_dDataSus datetime,@q_cCod varchar(20), @q_cGestiune varchar(20), @q_cCodi varchar(20), @q_cCont varchar(20),
	@q_TipStocuri varchar(20), @q_den varchar(20), @q_gr_cod varchar(20), @q_tip_pret varchar(1), @q_tiprap varchar(1)
select @q_dDataJos=@dDataJos, @q_dDataSus=@dDataSus, @q_cCod=@cCod, @q_cGestiune=@cGestiune, @q_cCodi=@cCodi, @q_cCont=@cCont,
	@q_TipStocuri=@TipStocuri, @q_den=@den,
	@q_gr_cod=@gr_cod+(case when isnull((select val_logica from par where tip_parametru='GE' and parametru='GRUPANIV'),0)=0 then '' else '%' end),
	@q_tip_pret=@tip_pret, @q_tiprap=@tiprap,
	@comanda=isnull(@comanda,'')

--select * from dbo.fStocuri(@q_dDataJos,@q_dDataSus,@q_cCod,@q_cGestiune,@q_cCodi,null,'',null,@q_cCont, 0,'','','','','') r
	if object_id('tempdb.dbo.#stocuri') is not null drop table #stocuri
	if object_id('tempdb.dbo.#de_cumulatstoc') is not null drop table #de_cumulatstoc
	if object_id('tempdb.dbo.#preturi') is not null drop table #preturi
	
select r.subunitate, r.cont,r.cod,r.cod_intrare,r.gestiune,
	(case when data<@q_dDataJos then '' else r.tert end) as tert, 
	(case when data<@q_dDataJos then 'SI' else r.tip_document end) as tip_document,
	(case when data<@q_dDataJos then '' else r.numar_document end) as numar_document,
	(case when data<@q_dDataJos then @q_dDataJos else r.data end) as data,
								sum((case when in_out=1 then 1
								when (in_out=2 and data<@q_dDataJos) then 1
								when (in_out=3 and data<@q_dDataJos) then -1
								else 0 end)*r.cantitate) as stoci,
	 sum((case when in_out=2 and data between @q_dDataJos and @q_dDataSus then r.cantitate else 0 end)) as intrari,
	sum((case when in_out=3 and r.data between @q_dDataJos and @q_dDataSus then cantitate else 0 end)) as iesiri,
	g.denumire_gestiune as DenGest,(case when @q_tiprap='F' then r.loc_de_munca else '' end) as loc_de_munca
	, max(r.predator) predator,
	max(case when @q_tip_pret='0' or @q_tip_pret='2' and g.Tip_gestiune<>'A' then r.pret
			when @q_tip_pret='1' or @q_tip_pret='2' and g.Tip_gestiune='A' then r.pret_cu_amanuntul else 0 end) as pretRaport,
	max(rtrim(r.comanda)) comanda, r.locatie, max(g.tip_gestiune) tip_gestiune,
	space(200) denumire_locatie
into #stocuri
from dbo.fStocuri(@q_dDataJos,@q_dDataSus,@q_cCod,@q_cGestiune,@q_cCodi,@q_gr_cod,@q_tiprap,@q_cCont, 0, @locatie, '', @comanda, '', '', '',null) r
	left outer join gestiuni g on  r.subunitate=g.subunitate and r.gestiune=g.cod_gestiune
--left outer join nomencl n on n.cod=r.cod
where (@q_TipStocuri='' or @q_TipStocuri='M' and left(r.cont,3) not in ('345','354','371','357') 
	or @q_TipStocuri='P' and left(r.cont,3) in ('345','354') or @q_TipStocuri='A' and left(r.cont,3) in ('371','357'))
--	and  (isnull(@q_gr_cod,'')='' or n.Grupa like @q_gr_cod+'%')
group by r.subunitate,
	r.cont,r.cod,r.cod_intrare,r.gestiune,r.pret,r.pret_cu_amanuntul,
	(case when data<@q_dDataJos then 'SI' else r.tip_document end),
	(case when data<@q_dDataJos then '' else r.numar_document end),
	(case when data<@q_dDataJos then @q_dDataJos else r.data end),
	(case when data<@q_dDataJos then '' else r.tert end),
	g.denumire_gestiune,(case when @q_tiprap='F' then r.loc_de_munca else '' end), r.locatie
having
	(
								abs(sum((case when in_out=1 then 1
								when (in_out=2 and data<@q_dDataJos) then 1
								when (in_out=3 and data<@q_dDataJos) then -1
								else 0 end)*r.cantitate))>0.0009
	or
	 abs(sum((case when in_out=2 and data between @q_dDataJos and @q_dDataSus then r.cantitate else 0 end)))>0.0009
	or
	abs(sum((case when in_out=3 and r.data between @q_dDataJos and @q_dDataSus then cantitate else 0 end)))>0.0009
	)

--create table #preturi (cod_produs varchar(20), um varchar(20), pret_vanzare decimal(12,3), data_inferioara datetime, data_superioara datetime)
	create table #preturi(cod varchar(20),nestlevel int)
	insert into #preturi
	select s.cod, @@NESTLEVEL
	from #stocuri s
	group by s.cod

	exec CreazaDiezPreturi
	
	if (@tip_pret>0)
	begin
		declare @px xml
		select @px=(select @categPret as categoriePret, @dDataSus as data,@cGestiune as gestiune for xml raw)
		exec wIaPreturi @sesiune=null,@parXML=@px
		update #stocuri set pretRaport=(case when @tip_pret='1' then pr.pret_amanunt when @tip_pret='2' and c.tip_gestiune='A' then pr.pret_vanzare when @tip_pret='3' then pr.pret_vanzare else c.pretRaport end)
			from #stocuri c inner join #preturi pr on pr.Cod=c.cod
	end
	/*
if @categpret is not null and @tip_pret<>0
begin
	insert into #preturi (cod_produs, um, pret_vanzare, data_inferioara, data_superioara)
	select p.Cod_produs, p.UM, max(p.Pret_vanzare) Pret_vanzare, data_inferioara, data_superioara from preturi p
	where (@categPret is not null and p.um=@categPret) and (@cCod is null or p.Cod_produs=@cCod)
	group by p.Cod_produs, p.UM, data_inferioara, data_superioara
	create index indprodus on #preturi(cod_produs)	--> indexul evita o intarziere semnificativa fata de rularea fara preturi pe categorii (varianta @tippret='s')
	
	update #stocuri set pretRaport=(case when @tip_pret='1' then pr.pret_amanunt when @tip_pret='2' and c.tip_gestiune='A' then pr.pret_vanzare else c.pretRaport end)
	
end
	*/
if (@q_tiprap='T')
	update s set s.DenGest=t.denumire
	from #stocuri s inner join terti t on t.subunitate=s.subunitate and s.gestiune=t.tert

if exists (select 1 from sys.objects where name='rapBalantaStocuri_completareSP')
	exec rapBalantaStocuri_completareSP

if (@grupare=4)	--> daca pe locatii se iau denumirile:
begin
	update r set denumire_locatie=rtrim(loc.Descriere)
	from #stocuri r
		inner join gestiuni g on r.gestiune=g.Cod_gestiune and ISNULL(g.detalii.value('(/*/@custodie)[1]','bit'),0)=0
		inner join locatii loc on loc.Cod_locatie=r.locatie and loc.Cod_gestiune=r.gestiune
	
	update r set denumire_locatie=rtrim(t.denumire)+ ISNULL('/'+RTRIM(it.Descriere),'')
	from #stocuri r,
		--inner join gestiuni g on r.gestiune=g.Cod_gestiune and ISNULL(g.detalii.value('(/*/@custodie)[1]','bit')=1
		terti t --on rtrim(t.tert)+REPLICATE(' ',13-LEN(rtrim(t.tert)))+ISNULL(rtrim(it.identificator),'')=r.locatie
		left join infotert it
			on it.subunitate=t.Subunitate and it.tert=t.tert and
				it.identificator<>''
	where rtrim(t.tert)+REPLICATE(' ',13-LEN(rtrim(t.tert)))+ISNULL(rtrim(it.identificator),'')=r.locatie
end

select
	rtrim(r.cont) cont, rtrim(r.cod) cod, rtrim(cod_intrare) cod_intrare, rtrim(r.gestiune) gestiune
	,r.pretRaport as pret, tip_document
	,rtrim(numar_document) numar_document, data, stoci, intrari, iesiri, rtrim(DenGest) DenGest
	,rtrim(n.denumire)+' ('+rtrim(n.um)+')' as DenProd
	,n.um, rtrim(n.grupa) grupa, rtrim(gr.denumire) as nume_grupa
	,rtrim(c.denumire_cont) as nume_cont, rtrim(r.loc_de_munca) loc_de_munca
	,rtrim(p.nume) as den_marca, rtrim(l.denumire) as den_lm, 
	rtrim(case when r.tip_document in('TE','TI') then r.predator 
		when r.tip_document in('SI') then '' 
		else ISNULL(t.denumire,r.tert) end) predator,
	--row_number() over (partition by cod order by (case when @ordonare=1 then n.Denumire else r.cod end),data) as nrrand,
	convert(float,0) as stocCumulat, convert(float,0) as valStocCumulat,
	isnull(rtrim(r.gestiune),'')+'|'+isnull(rtrim(case when @ordonare=1 then n.Denumire else r.cod end),'')+'|'+
		(case when @grupare4=0 then isnull(rtrim(cod_intrare),'') else '' end)+'|'+
		isnull((case when @grupare4=0 then '' else convert(varchar(40),convert(money,r.pretRaport)) end),'')
	as ordonareGrupare,	--> camp ajutator pentru ordinea calculului cumulat stoc cu update
	(case when tip_document='SI' then 1 when intrari<>0 then 2 else 3 end) ordineNivDoc,
	r.comanda, convert(varchar(500),r.locatie) locatie,
	convert(varchar(100),rtrim(case @grupare when 3 then rtrim(r.cont) when 5 then rtrim(n.grupa) else rtrim(r.gestiune) end)) grupare1,
	convert(varchar(100),(case when @centralizare>0 then rtrim(case @grupare when 0 then rtrim(n.grupa) when 1 then rtrim(r.cont) when 3 then rtrim(r.gestiune) when 4 then r.locatie when 5 then '' end) else '' end))  grupare2,
	convert(varchar(100),(case when @centralizare>1 then rtrim(r.cod) else '' end)) grupare3,
	convert(varchar(100),(case when @centralizare>2 then rtrim(case when @grupare4=1 then rtrim(r.pretRaport) else rtrim(cod_intrare) end) else '' end)) grupare4,
	convert(varchar(100),(case when @centralizare>2 then (case when r.tip_document='SI' then null else /*sp */ rtrim(tip_document)+rtrim(numar_document)+'|'+convert(varchar(10),data,112)+'|'+rtrim(cod_intrare) /* sp*/ end) else '' end)) grupare5,
	convert(varchar(100),(case @grupare when 3 then rtrim(r.cont)+' '+rtrim(isnull(c.Denumire_cont,'')) when 5 then rtrim(isnull(n.grupa,''))+' '+rtrim(isnull(gr.Denumire,''))
					else (case when @q_tiprap='F' then rtrim(isnull(p.Nume,'')) else rtrim(isnull(DenGest,'')) end)+' ('+rtrim(r.gestiune)+')'
				end)) denumire1,
	convert(varchar(100),(case when @centralizare>0 then
		rtrim(case @grupare
				when 0 then rtrim(isnull(n.grupa,''))+' '+rtrim(isnull(gr.Denumire,''))
				when 1 then rtrim(r.cont)+' '+rtrim(isnull(c.Denumire_cont,''))
				when 3 then (case when @q_tiprap='F' then rtrim(isnull(p.Nume,'')) else rtrim(isnull(DenGest,'')) end)+' ('+rtrim(r.gestiune)+')'
				when 4 then rtrim(r.denumire_locatie)+' ('+rtrim(r.locatie)+')'
				else '' 
				end)
			else '' end))
		denumire2,
	convert(varchar(100),(case when @centralizare>1 then rtrim(r.cod)+' '+rtrim(isnull(n.denumire,''))+' ('+rtrim(isnull(n.um,''))+')' else '' end)) denumire3,
	convert(varchar(100),(case when @centralizare>2 then 
		rtrim(case when @grupare4=1 then rtrim(r.pretRaport) 
					else rtrim(r.cod_intrare)+' '+CONVERT(VARCHAR, r.pretRaport) end) else '' end))
		denumire4
	into #de_cumulatstoc
from #stocuri r
	left join nomencl n on n.cod=r.cod
	left join grupe gr on gr.grupa=n.grupa
	left join conturi c on c.cont=r.cont and c.Subunitate=r.subunitate
	left join personal p on r.gestiune = p.marca
	left join lm l on l.cod=r.loc_de_munca
	left join terti t on r.tert=t.tert and r.subunitate=t.Subunitate
where (isnull(n.denumire,'')='' or n.denumire like '%'+isnull(@q_den,'')+'%')
	and (@furnizor_nomenclator is null or n.furnizor=@furnizor_nomenclator)
	and (0<>(select sum(stoci) from #stocuri si where si.cod_intrare=r.cod_intrare and si.cod=r.cod
			and si.gestiune=r.gestiune and si.tip_document='SI' and si.tip_document=r.tip_document)
		or r.data between @q_dDataJos and @q_dDataSus --and r.tip_document<>'SI'
	)
order by r.gestiune,
		(case when @ordonare=1 then n.Denumire else r.cod end),
		cod_intrare,
		data

-->	se calculeaza valori cumulate ale stocului in cadrul codurilor de intrare:
declare @stoc float, @valoare float, @grupareCumulare varchar(500)
select @stoc=0, @valoare=0, @grupareCumulare=''
update d set	@stoc=(case when @grupareCumulare=d.ordonareGrupare then @stoc else 0 end)+
						d.stoci+d.intrari-d.iesiri, stocCumulat=@stoc,
				@valoare=(case when @grupareCumulare=d.ordonareGrupare then @valoare else 0 end)+
						(d.stoci+d.intrari-d.iesiri)*d.pret,
				valStocCumulat=@valoare,
				@grupareCumulare=d.ordonareGrupare
	from #de_cumulatstoc d
--/*	
--> re-organizare pentru centralizare functionala in raport indiferent de versiunea de Reporting (2005, 2008)
if @centralizare<3
update d set grupare1='',
			grupare2=(case @centralizare when 2 then grupare1 else '' end),
			grupare3=(case @centralizare when 1 then grupare1 when 2 then grupare2 else '' end),
			grupare4=(case @centralizare when 0 then grupare1 when 1 then grupare2 when 2 then grupare3 else '' end),
			denumire1=(case @centralizare when 2 then 'Total unitate' else '' end),
			denumire2=(case @centralizare when 1 then 'Total unitate' when 2 then denumire1 else '' end),
			denumire3=(case @centralizare when 0 then 'Total unitate' when 1 then denumire1 when 2 then denumire2 else '' end),
			denumire4=(case @centralizare when 0 then denumire1 when 1 then denumire2 when 2 then denumire3 else '' end)
	from #de_cumulatstoc d
---*/
	
select max(d.ordineNivDoc) ordineNivDoc, max(cont) cont, max(cod) cod, max(cod_intrare) cod_intrare,
	max(gestiune) gestiune, 
	(case when sum(abs(d.stoci)+abs(d.intrari)+abs(d.iesiri))=0 then 0
		else sum((abs(d.stoci)+abs(d.intrari)+abs(d.iesiri))*pret)/sum(abs(d.stoci)+abs(d.intrari)+abs(d.iesiri)) end)	--*/
/*	(case when sum(d.stoci+d.intrari-d.iesiri)=0 then 0
		else sum((d.stoci+d.intrari-d.iesiri)*pret)/sum(d.stoci+d.intrari-d.iesiri) end)	--*/
		pret,
	max(tip_document) tip_document, max(numar_document) numar_document, max(data) data, sum(stoci) stoci, 
	sum(intrari) intrari, sum(iesiri) iesiri, max(DenGest) DenGest, max(DenProd) DenProd, max(um) um,
	max(grupa) grupa, max(nume_grupa) nume_grupa, max(nume_cont) nume_cont, max(loc_de_munca) loc_de_munca,
	max(den_marca) den_marca, max(den_lm) den_lm, max(predator) predator, max(stocCumulat) stocCumulat,
	max(valStocCumulat) valStocCumulat, max(comanda) comanda,
	sum(stoci*pret) as valStoci, sum(intrari*pret) valIntrari, sum(iesiri*pret) valIesiri,
	grupare1, grupare2, grupare3, grupare4, grupare5,
	max(denumire1) denumire1, max(denumire2) denumire2, max(denumire3) denumire3, max(denumire4) denumire4,
	max(d.locatie) locatie
	,max(ordonareGrupare)
from #de_cumulatstoc d
	group by grupare1, grupare2, grupare3, grupare4, grupare5
order by max(d.ordineNivDoc), max(ordonareGrupare), max(data), max(numar_document)

/*
select d.ordineNivDoc, cont, cod, cod_intrare, gestiune, pret, tip_document, numar_document, data, stoci, 
	intrari, iesiri, DenGest, DenProd, um, grupa, nume_grupa, nume_cont, loc_de_munca,
	den_marca, den_lm, predator, stocCumulat, valStocCumulat, comanda --,ordonareGrupare
from #de_cumulatstoc d order by --d.cod, 
	d.ordineNivDoc
	*/
if object_id('tempdb.dbo.#stocuri') is not null drop table #stocuri
if object_id('tempdb.dbo.#de_cumulatstoc') is not null drop table #de_cumulatstoc
if object_id('tempdb.dbo.#preturi') is not null drop table #preturi