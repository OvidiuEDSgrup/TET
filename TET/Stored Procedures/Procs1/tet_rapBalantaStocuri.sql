
--***
create procedure [dbo].[tet_rapBalantaStocuri](@dDataJos datetime, @dDataSus datetime,@cCod varchar(20), @cGestiune varchar(20), @cCodi varchar(20), @cCont varchar(20),
	@TipStocuri varchar(20), @den varchar(20), @gr_cod varchar(20), @tip_pret varchar(1), @tiprap varchar(20), @comanda varchar(40)='')
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
	@q_TipStocuri varchar(20), @q_den varchar(20), @q_gr_cod varchar(20), @q_tip_pret varchar(1), @q_tiprap varchar(1), @q_comanda varchar(40)
select @q_dDataJos=@dDataJos, @q_dDataSus=@dDataSus,@q_cCod=@cCod, @q_cGestiune=@cGestiune, @q_cCodi=@cCodi, @q_cCont=@cCont,
	@q_TipStocuri=@TipStocuri, @q_den=@den, @q_gr_cod=@gr_cod, @q_tip_pret=@tip_pret, @q_tiprap=@tiprap, @q_comanda=@comanda

--select * from dbo.fStocuri(@q_dDataJos,@q_dDataSus,@q_cCod,@q_cGestiune,@q_cCodi,null,'',null,@q_cCont, 0,'','','','','') r
	if object_id('tempdb.dbo.#stocuri') is not null drop table #stocuri

select r.cont,r.cod,r.cod_intrare,r.gestiune,r.pret,
	(case when data<@q_dDataJos then 'SI' else r.tip_document end) as tip_document,
	(case when data<@q_dDataJos then '' else r.numar_document end) as numar_document,
	(case when data<@q_dDataJos then @q_dDataJos else r.data end) as data,
								sum((case when in_out=1 then 1
								when (in_out=2 and data<@q_dDataJos) then 1
								when (in_out=3 and data<@q_dDataJos) then -1
								else 0 end)*r.cantitate) as stoci,
	 sum((case when in_out=2 and data between @q_dDataJos and @q_dDataSus then r.cantitate else 0 end)) as intrari,
	sum((case when in_out=3 and r.data between @q_dDataJos and @q_dDataSus then cantitate else 0 end)) as iesiri,
	g.denumire_gestiune as DenGest,(case when @q_tiprap='F' then r.loc_de_munca else r.comanda end) as loc_de_munca
	,r.pret_cu_amanuntul, max(r.predator) predator, MAX(tert) as tert, MAX(tip_miscare) as tip_miscare, MAX(in_out) as in_out
	,MAX(r.furnizor) as furnizor
into #stocuri
from dbo.fStocuri(@q_dDataJos,@q_dDataSus,@q_cCod,@q_cGestiune,@q_cCodi,@q_gr_cod,@q_tiprap,@q_cCont, 0, '', '', @comanda, '', '','') r
	left outer join gestiuni g on  r.subunitate=g.subunitate and r.gestiune=g.cod_gestiune
--left outer join nomencl n on n.cod=r.cod
where (@q_TipStocuri='' or @q_TipStocuri='M' and left(r.cont,3) not in ('345','354','371','357') 
	or @q_TipStocuri='P' and left(r.cont,3) in ('345','354') or @q_TipStocuri='A' and left(r.cont,3) in ('371','357'))
--	and  (isnull(@q_gr_cod,'')='' or n.Grupa like @q_gr_cod+'%')
group by 
	r.cont,r.cod,r.cod_intrare,r.gestiune,r.pret,r.pret_cu_amanuntul,
	(case when data<@q_dDataJos then 'SI' else r.tip_document end),
	(case when data<@q_dDataJos then '' else r.numar_document end),
	(case when data<@q_dDataJos then @q_dDataJos else r.data end),
	g.denumire_gestiune,(case when @q_tiprap='F' then r.loc_de_munca else r.comanda end)
having
	(
								sum((case when in_out=1 then 1
								when (in_out=2 and data<@q_dDataJos) then 1
								when (in_out=3 and data<@q_dDataJos) then -1
								else 0 end)*r.cantitate)<>0
	or
	 sum((case when in_out=2 and data between @q_dDataJos and @q_dDataSus then r.cantitate else 0 end))<>0
	or
	sum((case when in_out=3 and r.data between @q_dDataJos and @q_dDataSus then cantitate else 0 end))<>0
	)


select
	rtrim(r.cont) cont, rtrim(r.cod) cod, rtrim(cod_intrare) cod_intrare, rtrim(r.gestiune) gestiune
	,(case when @q_tip_pret='0' then r.pret else r.pret_cu_amanuntul end) as pret, tip_document
	,rtrim(numar_document) numar_document, data, stoci, intrari, iesiri, rtrim(DenGest) DenGest
	,rtrim(n.denumire)+' ('+rtrim(n.um)+')' as DenProd
	,n.um, rtrim(n.grupa) grupa, rtrim(gr.denumire) as nume_grupa
	,rtrim(c.denumire_cont) as nume_cont, rtrim(r.loc_de_munca) loc_de_munca
	,rtrim(p.nume) as den_marca, rtrim(isnull(l.denumire,cm.descriere)) as den_lm 
	,rtrim(case when r.tip_document not in('SI','AC') then '' else r.predator end) predator
	,r.tert, RTRIM(isnull(t.Denumire,lm.denumire)) as den_tert, r.tip_miscare, r.in_out
	,isnull(nullif(r.furnizor,''),n.Furnizor) as furnizor, RTRIM(f.Denumire) as den_furnizor
--into tmpRefreshLuci		-- pt refresh fields in Reporting
from #stocuri r
	left outer join nomencl n on n.cod=r.cod
	left join grupe gr on gr.grupa=n.grupa
	left join conturi c on c.cont=r.cont
	left join personal p on r.gestiune = p.marca
	left join lm l on @q_tiprap='F' and l.cod=r.loc_de_munca
	left join comenzi cm on @q_tiprap<>'F' and cm.Comanda=r.loc_de_munca
	left join terti t on t.Tert=r.tert
	left join lm on lm.Cod=r.tert
	left join terti f on f.Subunitate='1' and f.Tert=isnull(nullif(r.furnizor,''),n.Furnizor)
where (isnull(n.denumire,'')='' or n.denumire like '%'+isnull(@q_den,'')+'%')
	and (0<>(select sum(stoci) from #stocuri si where si.cod_intrare=r.cod_intrare and si.cod=r.cod and si.gestiune=r.gestiune 
				and si.tip_document='SI' and si.tip_document=r.tip_document)
		or r.data between @q_dDataJos and @q_dDataSus --and r.tip_document<>'SI'
	)
order by data

if object_id('tempdb.dbo.#stocuri') is not null drop table #stocuri

