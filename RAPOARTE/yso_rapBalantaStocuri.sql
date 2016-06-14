--/*	Procedura pt rapoartele de Balanta stocuri (web).	
if exists (select 1 from sysobjects o where o.name='yso_rapBalantaStocuri')
	drop procedure yso_rapBalantaStocuriSP
--*/
GO
--/*** pt TESTE decomenteaza aceasta linie
create procedure yso_rapBalantaStocuri(--*/ declare
	@Sesiune varchar(50)=null,	-->	parametrul sesiune nu va avea efect pana ce nu-l vom trimite catre ftert
	@Data_inf_perioada datetime, @Data_sup_perioada datetime,@Cod_articol varchar(20), @Gestiune varchar(20), @Cod_intrare varchar(20), @Cont varchar(20),
	@Tip_stocuri varchar(20), @Denumire_articol varchar(20), @Grupa_articole varchar(20), 
	@Tip_pret varchar(1)=0,	-->	0=stoc, 1=amanuntul, 2=pe tip gestiune, 3=vanzare
	@Tip_raport varchar(20),-- @Ordonare varchar(20)=0,	--> @ordonare=1 ordonare alfabetica pe nume produs, =0 ordonare pe cod produs
	--@grupare4 bit=0,							--> grupare pe pret (0=nu, 1=da)
	@Comanda varchar(200)=null,
	--@centralizare int=3,	--> 0=grupare1, 1=grupare2, 2=cod, 3=fara centralizare
	--@grupare int=0,	-->	0=Gestiuni si grupe, 1=Gestiuni si conturi, 3=Conturi si gestiuni, 4=Gestiuni si locatii, 5=Grupe (si nimic)
	@Categorie_pret smallint=null,
	@Locatie varchar(30)=null,
	@Furnizor_nomenclator varchar(20)=null--/*sp
	,@Lot varchar(20)=null
	,@Set_gestiuni varchar(50)=null 
	--sp*/,@UM2 bit=1
	
	
/* si comenteaza aceasta linie pt TESTE
select @Data_inf_perioada='2013-09-01 00:00:00',@Data_sup_perioada='2013-10-30 00:00:00',@Cod_articol=null,@Gestiune=NULL,@Cod_intrare=NULL,@Cont=NULL
	,@Tip_stocuri=N'',@den_articol=NULL,@Grupa_articole=NULL,@tip_pret=N'0',@Tip_raport=N'D',@comanda=NULL
	,@locatie=NULL,@furnizor_nomenclator=NULL,@Lot=null
--*/)as

declare @dDataJos datetime, @dDataSus datetime,@cCod varchar(20), @cGestiune varchar(20), @cCodi varchar(20), @cCont varchar(20),
	@TipStocuri varchar(20), @den varchar(20), @gr_cod varchar(20), 
	--@tip_pret varchar(1)=0,	-->	0=stoc, 1=amanuntul, 2=pe tip gestiune, 3=vanzare
	@tiprap varchar(20), @ordonare varchar(20)=0,	--> @ordonare=1 ordonare alfabetica pe nume produs, =0 ordonare pe cod produs
	@grupare4 bit=0,							--> grupare pe pret (0=nu, 1=da)
	--@comanda varchar(200)=null,
	@centralizare int=3,	--> 0=grupare1, 1=grupare2, 2=cod, 3=fara centralizare
	@grupare int=0,	-->	0=Gestiuni si grupe, 1=Gestiuni si conturi, 3=Conturi si gestiuni, 4=Gestiuni si locatii, 5=Grupe (si nimic)
	@categpret smallint=null
	--@locatie varchar(30)=null,
	--@furnizor_nomenclator varchar(20)=null--/*sp
	--,@UM2 bit=1
	
select @dDataJos=@Data_inf_perioada,@dDataSus=@Data_sup_perioada,@cCod=@Cod_articol,@cGestiune=@Gestiune,@cCodi=@Cod_intrare,@cCont=@Cont,@TipStocuri=@Tip_stocuri
	,@den=@Denumire_articol,@gr_cod=@Grupa_articole,@tip_pret=@Tip_pret,@tiprap=@Tip_raport,@grupare4=0,@comanda=@Comanda,@centralizare=N'3'
	,@grupare=N'0',@categpret=@Categorie_pret
	,@locatie=@Locatie,@furnizor_nomenclator=@Furnizor_nomenclator,@lot=@Lot
	,@ordonare=0

set transaction isolation level read uncommitted
declare @q_dDataJos datetime, @q_dDataSus datetime,@q_cCod varchar(20), @q_cGestiune varchar(20), @q_cCodi varchar(20), @q_cCont varchar(20),
	@q_TipStocuri varchar(20), @q_den varchar(20), @q_gr_cod varchar(20), @q_tip_pret varchar(1), @q_tiprap varchar(1)
select @q_dDataJos=@dDataJos, @q_dDataSus=@dDataSus, @q_cCod=@cCod, @q_cGestiune=@cGestiune, @q_cCodi=@cCodi, @q_cCont=@cCont,
	@q_TipStocuri=@TipStocuri, @q_den=@den,
	@q_gr_cod=@gr_cod+(case when isnull((select val_logica from par where tip_parametru='GE' and parametru='GRUPANIV'),0)=0 then '' else '%' end),
	@q_tip_pret=@tip_pret, @q_tiprap=@tiprap,
	@comanda=isnull(@comanda,'')

declare @parXML xml
select @parXML=(select @sesiune as sesiune for xml raw)

if @lot is not null and @ccod is null
begin
	raiserror('Nu este permisa filtrarea pe lot in absenta filtrului pe cod produs!',16,1)
	return
end

--select * from dbo.fStocuri(@q_dDataJos,@q_dDataSus,@q_cCod,@q_cGestiune,@q_cCodi,null,'',null,@q_cCont, 0,'','','','','') r
	if object_id('tempdb.dbo.#stocuri') is not null drop table #stocuri
	if object_id('tempdb.dbo.#de_cumulatstoc') is not null drop table #de_cumulatstoc
	if object_id('tempdb.dbo.#preturi') is not null drop table #preturi
	
select r.subunitate, r.cont,r.cod,r.cod_intrare,r.gestiune,
	(case when r.data<@q_dDataJos then '' else r.tert end) as tert, 
	(case when r.data<@q_dDataJos then 'SI' else r.tip_document end) as tip_document,
	(case when r.data<@q_dDataJos then '' else r.numar_document end) as numar_document,
	(case when r.data<@q_dDataJos then @q_dDataJos else r.data end) as data,
	(case when in_out=1 then 1
		when (in_out=2 and r.data<@q_dDataJos) then 1
		when (in_out=3 and r.data<@q_dDataJos) then -1
		else 0 end)*r.cantitate as stoci,--/*sp
	(case when in_out=1 then 1
		when (in_out=2 and r.data<@q_dDataJos) then 1
		when (in_out=3 and r.data<@q_dDataJos) then -1
		else 0 end)*r.cantitate_UM2 as stoci2, --sp*/
	(case when in_out=2 and r.data between @q_dDataJos and @q_dDataSus then r.cantitate else 0 end) as intrari,--/*sp
	(case when in_out=2 and r.data between @q_dDataJos and @q_dDataSus then r.cantitate_UM2 else 0 end) as intrari2,	--sp*/
	(case when in_out=3 and r.data between @q_dDataJos and @q_dDataSus then r.cantitate else 0 end) as iesiri,--/*sp
	(case when in_out=3 and r.data between @q_dDataJos and @q_dDataSus then r.cantitate_UM2 else 0 end) as iesiri2, --sp*/ 
	den_gestiune=rtrim(g.Denumire_gestiune), (case when @q_tiprap='F' then r.loc_de_munca else '' end) as loc_de_munca
	, r.predator,
	(case when @q_tip_pret='0' or @q_tip_pret='2' and g.Tip_gestiune<>'A' then r.pret
			when @q_tip_pret='1' or @q_tip_pret='2' and g.Tip_gestiune='A' then r.pret_cu_amanuntul else 0 end) as pretRaport,
	rtrim(r.comanda) comanda, r.locatie, g.tip_gestiune,
	convert(varchar(200),'') den_locatie--/*SP
	,r.lot, r.idIntrareFirma, r.idIntrare
	,den_cod=rtrim(n.Denumire), tip_nomenclator=rtrim(n.tip), grupa=rtrim(n.Grupa), n.UM, UM2=rtrim(n.UM_1), n.Coeficient_conversie_1, n.Greutate_specifica
	, furnizor_nomenclator=rtrim(n.Furnizor), den_furnizor=RTRIM(f.Denumire)
	,den_grupa=rtrim(gr.Denumire), grupa_parinte=rtrim(gr.grupa_parinte), den_cont=RTRIM(c.Denumire_cont)
	,p.Nume, p.Marca
	,den_loc_de_munca=rtrim(l.Denumire),loc_de_munca_parinte=l.Cod_parinte 
	,den_tert=rtrim(t.Denumire), t.Cod_fiscal
--SP*/,detalii_nomencl=n.detalii, detalii_intrare=intr.detalii, detalii_intrarei=intri.detalii
into #stocuri
from dbo.fStocuri(@q_dDataJos,@q_dDataSus,@q_cCod,@q_cGestiune,@q_cCodi,@q_gr_cod,@q_tiprap,@q_cCont, 0, @locatie, '', @comanda, '', '', '', @parXML) r
	left join gestiuni g on  r.subunitate=g.subunitate and r.gestiune=g.cod_gestiune
	left join nomencl n on n.cod=r.cod
	left join grupe gr on gr.grupa=n.grupa and n.Tip=gr.Tip_de_nomenclator
	left join conturi c on c.cont=r.cont and c.Subunitate=r.subunitate
	left join personal p on r.gestiune = p.marca 
	left join lm l on l.cod=r.loc_de_munca
	left join terti t on r.tert=t.tert and r.subunitate=t.Subunitate --/*SP
	left join comenzi cm on @q_tiprap<>'F' and cm.Comanda=r.loc_de_munca
	left join terti f on n.Furnizor=f.tert and f.Subunitate='1'
	left join pozdoc intr on intr.idPozDoc=r.idIntrare
	left join pozdoc intri on intri.idPozDoc=r.idIntrareFirma --SP*/
where (@q_TipStocuri='' or @q_TipStocuri='M' and left(r.cont,3) not in ('345','354','371','357') 
	or @q_TipStocuri='P' and left(r.cont,3) in ('345','354') or @q_TipStocuri='A' and left(r.cont,3) in ('371','357'))
	and (isnull(n.denumire,'')='' or n.denumire like '%'+isnull(@q_den,'')+'%')
	and (@furnizor_nomenclator is null or n.furnizor=@furnizor_nomenclator)
	and (@Set_gestiuni is null or rtrim(r.gestiune) like RTRIM(@Set_gestiuni)+'%')
	--and (0<>(select sum(stoci) from #stocuri si where si.cod_intrare=r.cod_intrare and si.cod=r.cod
	--		and si.gestiune=r.gestiune and si.tip_document='SI' and si.tip_document=r.tip_document)
	--	or r.data between @q_dDataJos and @q_dDataSus --and r.tip_document<>'SI'
	--	)
--	and  (isnull(@q_gr_cod,'')='' or n.Grupa like @q_gr_cod+'%')
--group by r.subunitate,
--	r.cont,r.cod,--/*SP 
--	r.lot,r.idIntrareFirma,r.idIntrare, --SP*/
--	r.cod_intrare,r.gestiune,r.pret,r.pret_cu_amanuntul,
--	(case when r.data<@q_dDataJos then 'SI' else r.tip_document end),
--	(case when r.data<@q_dDataJos then '' else r.numar_document end),
--	(case when r.data<@q_dDataJos then @q_dDataJos else r.data end),
--	(case when r.data<@q_dDataJos then '' else r.tert end),
--	g.den_gestiune,(case when @q_tiprap='F' then r.loc_de_munca else '' end), r.locatie
--having
--	(
--								abs(sum((case when in_out=1 then 1
--								when (in_out=2 and r.data<@q_dDataJos) then 1
--								when (in_out=3 and r.data<@q_dDataJos) then -1
--								else 0 end)*r.cantitate))>0.0009
--	or
--	 abs(sum((case when in_out=2 and r.data between @q_dDataJos and @q_dDataSus then r.cantitate else 0 end)))>0.0009
--	or
--	abs(sum((case when in_out=3 and r.data between @q_dDataJos and @q_dDataSus then cantitate else 0 end)))>0.0009
	--)

	create table #preturi(cod varchar(20),nestlevel int)
	exec CreazaDiezPreturi
	
	if (@tip_pret>2) -- da efect doar daca s-a optat pentru "Pret vanzare", adica sa aduca din tabela de preturi 
	begin
		insert into #preturi
		select s.cod, @@NESTLEVEL
		from #stocuri s
		group by s.cod

		declare @px xml
		select @px=(select @categPret as categoriePret, @dDataSus as data,@cGestiune as gestiune for xml raw)
		exec wIaPreturi @sesiune=@sesiune,@parXML=@px
		update #stocuri set pretRaport=pr.pret_amanunt
			from #stocuri c inner join #preturi pr on pr.Cod=c.cod
	end

if (@q_tiprap='T')
	update s set s.DenGest=t.denumire
	from #stocuri s inner join terti t on t.subunitate=s.subunitate and s.gestiune=t.tert

--if (@grupare=4)	--> daca pe locatii se iau denumirile:
begin
	update r set den_locatie=rtrim(loc.Descriere)
	from #stocuri r
		inner join gestiuni g on r.gestiune=g.Cod_gestiune and ISNULL(g.detalii.value('(/*/@custodie)[1]','bit'),0)=0
		inner join locatii loc on loc.Cod_locatie=r.locatie and loc.Cod_gestiune=r.gestiune
	
	update r set den_locatie=rtrim(t.denumire)+ ISNULL('/'+RTRIM(it.Descriere),'')
	from #stocuri r,
		--inner join gestiuni g on r.gestiune=g.Cod_gestiune and ISNULL(g.detalii.value('(/*/@custodie)[1]','bit')=1
		terti t --on rtrim(t.tert)+REPLICATE(' ',13-LEN(rtrim(t.tert)))+ISNULL(rtrim(it.identificator),'')=r.locatie
		left join infotert it
			on it.subunitate=t.Subunitate and it.tert=t.tert and
				it.identificator<>''
	where rtrim(t.tert)+REPLICATE(' ',13-LEN(rtrim(t.tert)))+ISNULL(rtrim(it.identificator),'')=r.locatie
end

select *
,(stoci*s.pretRaport) as valStoci, (intrari*s.pretRaport) valIntrari, (iesiri*s.pretRaport) valIesiri
from #stocuri s

if object_id('tempdb.dbo.#stocuri') is not null drop table #stocuri
if object_id('tempdb.dbo.#de_cumulatstoc') is not null drop table #de_cumulatstoc
if object_id('tempdb.dbo.#preturi') is not null drop table #preturi