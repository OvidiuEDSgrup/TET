--***
Create procedure rapStocVechimi @sesiune varchar(50)=null,
	@dDataRef datetime, @cGestiune char(9),
	@cCod_range char(20), @cCont_range varchar(40),
	@i1 int, @i2 int, @i3 int, @i4 int, @ZileVechime int,
	@TipStoc char(1)='',	--> Depozit, Folosinta, Custodie
	@GRLocM char(1)='', @grupa char(13)=null,
	@Grupare varchar(1)='G',	--> G=gestiune, C=cont, M= gestiune si loc de munca
	@tippret varchar(1)='s', --> s,t,v s=pret de stoc, t=f(tip gestiune), v=pret vanzare
	@categpret smallint=null,
	@locatie varchar(200)=null,
	@dupa_data_intrarii_in_firma bit=0
		
as
/*
Exemplu de rulare:
exec rapStocVechimi @dDataRef ='2013-12-31', @cGestiune= '88',
	@cCod_range='0000362', @cCont_range=null,
	@i1 =30, @i2 =60, @i3 =270, @i4= 365, @ZileVechime =0, @TipStoc ='', @GRLocM ='', @grupa =null,
	@Grupare ='G',	--> G=gestiune, C=cont, M= gestiune si loc de munca
	@tippret ='s', --> s,t,v s=pret de stoc, t=f(tip gestiune), v=pret vanzare
	@categpret =null,
	@locatie =null,
	@dupa_data_intrarii_in_firma=1
*/
	set transaction isolation level read uncommitted

if object_ID('tempdb..#stocvech') is not null drop table #stocvech
if object_ID('tempdb..#stocuri') is not null drop table #stocuri
if object_id('tempdb.dbo.#preturi') is not null drop table #preturi

declare @cSub varchar(9)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @cSub output
select @cSub=rtrim(@cSub)

set @cCont_range=rtrim(@cCont_range)+'%'
declare @nStoc1 float, @nStoc2 float, @nStoc3 float, @nStoc4 float, @nStoc5 float, 
		@nVal1 float, @nVal2 float, @nVal3 float, @nVal4 float, @nVal5 float, 
		@cTip_gest char(1), @cGest char(9), @cCod char(20), @cDen char(80), @cLm varchar(20), @cont varchar(40), @dData datetime, @nPret float, @nStoc float, 
		@gTip_gest char(1), @gGest char(9), @gCod char(20), @gDen char(80), @gLm varchar(20), @gCont varchar(40)
declare @comanda_str varchar(max)	--> cu sql dinamic pe unde e benefic

if @cCod_range='' set @cCod_range=null
if @cGestiune='' set @cGestiune=null
if @Grupa='' set @grupa=null
	/**	se iau datele din stocuri si se trec printr-un cursor pentru impartirea stocurilor in functie de intervalele cerute: */

	declare @p xml
	select @p=(select @dDataRef dDataSus, @cCod_range cCod, @cGestiune cGestiune, @cCont_range ccont, 1 GrCod, 1 GrGest, 1 GrCodi, @TipStoc TipStoc, @locatie Locatie for xml raw)

		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
			if @dDataRef is not null
		exec pstoc @sesiune='', @parxml=@p
		else if isnull(@TipStoc,'') in ('','D')
		begin
			set @dDataRef=convert(varchar(20),getdate(),102)
			insert into #docstoc(subunitate, gestiune, cont, cod, data, data_stoc, cod_intrare, pret,
				tip_document, numar_document, cantitate, cantitate_UM2, tip_miscare, in_out, 
				predator, jurnal, tert, serie, pret_cu_amanuntul, tip_gestiune, locatie, 
				data_expirarii, TVA_neexigibil, pret_vanzare, accize_cump, loc_de_munca, comanda, 
				[contract], furnizor, lot, numar_pozitie, cont_corespondent, schimb, idIntrareFirma, idIntrare, stoc)
			select '1', s.cod_gestiune gestiune, s.cont cont, s.cod, s.data, '1901-1-1', '', s.pret,
					'', '', 0,0,'', 0,
					'', '', '', '', s.pret_cu_amanuntul, s.tip_gestiune, '',
					'1901-1-1', 0, 0, 0, s.loc_de_munca as loc_de_munca, '',
					'', '', '', '', '', '', isnull(idIntrareFirma,0) idIntrareFirma, 0, s.stoc stoc
			from stocuri s 
			where s.subunitate = @cSub
			--and datediff(d,s.data,@dDataRef) >= isnull(@ZileVechime, 0)
			and (isnull(@cGestiune, '') = '' or s.cod_gestiune = @cGestiune) 
			and (isnull(@cCod_range, '') = '' or s.cod = @cCod_range) 
			and (isnull(@cCont_range, '') = '' or s.cont like rtrim(@cCont_range)+'%') 
			and (isnull(@locatie, '') = '' or s.Locatie = @locatie) 
		end
	update s set
		pret=(case when s.tip_gestiune='A' then s.pret_cu_amanuntul else s.pret end)
		,loc_de_munca=isnull(s.loc_de_munca,'')
	from #docstoc s
	
--declare cstoc cursor for
select s.tip_gestiune, s.gestiune, s.cod, s.loc_de_munca as loc_de_munca, s.data, 
	s.pret, sum(s.stoc) stoc, max(s.cont) cont, max(isnull(idIntrareFirma,0)) idIntrareFirma
into #stocuri
--from dbo.fStocuriCen(@dDataRef, @cCod_range, @cGestiune, null, 1, 1, 1, @TipStoc, '', '', @locatie, '', '', '', '', '') s
from #docstoc s
group by s.tip_gestiune, s.gestiune, s.cod, s.loc_de_munca, s.cont, s.data, s.pret, (case when @dupa_data_intrarii_in_firma=1 then isnull(idIntrareFirma,0) else 0 end)
order by s.tip_gestiune, s.gestiune, s.cod, s.loc_de_munca

select @comanda_str=''
if @dupa_data_intrarii_in_firma=1
	select @comanda_str='
	update s set data=p.data
	from #stocuri s inner join pozdoc p on s.idIntrareFirma=p.idpozdoc
	'
exec(@comanda_str)

	/**	tabela pentru retinerea temporara a stocurilor pe vechimi, pana la trimiterea datelor la raport */
CREATE TABLE #stocvech(	Subunitate varchar(100) NOT NULL, Tip_gestiune varchar(100) NOT NULL, Gestiune varchar(100) NOT NULL,
	Cod varchar(100) NOT NULL, Stoc1 float NOT NULL, Valoare1 float NOT NULL, Stoc2 float NOT NULL,
	Valoare2 float NOT NULL, Stoc3 float NOT NULL, Valoare3 float NOT NULL, Stoc4 float NOT NULL, Valoare4 float NOT NULL,
	Stoc5 float NOT NULL, Valoare5 float NOT NULL, Locm varchar(100) NOT NULL, Cont varchar(100), grupare varchar(1000)
)
CREATE --UNIQUE 
	CLUSTERED INDEX indx_Stocvech ON #stocvech 
(
	Subunitate ASC,
	Tip_gestiune ASC,
	Gestiune ASC,
	Cod ASC,
	Locm ASC,
	Cont asc
)

select @comanda_str='
declare @dDataRef datetime, @grupare varchar(20),
		@data1 datetime, @data2 datetime, @data3 datetime, @data4 datetime, @data5 datetime	--> intervalele pe care se repartizeaza stocul si valoarea
select @dDataRef='''+convert(varchar(20),@dDataRef,102)+''', @grupare='''+@grupare+'''
select	@data1=@dDataRef,
		@data2=@dDataRef-'+convert(varchar(20),@i1)+',
		@data3=@dDataRef-'+convert(varchar(20),@i2)+',
		@data4=@dDataRef-'+convert(varchar(20),@i3)+',
		@data5=@dDataRef-'+convert(varchar(20),@i4)+'
		
insert into #stocvech(Subunitate, Tip_gestiune, Gestiune,
	Cod, Stoc1, Valoare1, Stoc2,
	Valoare2, Stoc3, Valoare3, Stoc4, Valoare4,
	Stoc5, Valoare5, Locm, Cont)
select '''+@cSub+''', tip_gestiune , max(gestiune), max(cod),
	sum(case when data between @data2 and @data1 then stoc else 0 end), sum(case when data between @data2 and @data1 then pret*stoc else 0 end),	--> -1 pt ca la limita superioara sa fie mai mic strict
	sum(case when data between @data3 and @data2-1 then stoc else 0 end), sum(case when data between @data3 and @data2-1 then pret*stoc else 0 end),
	sum(case when data between @data4 and @data3-1 then stoc else 0 end), sum(case when data between @data4 and @data3-1 then pret*stoc else 0 end),
	sum(case when data between @data5 and @data4-1 then stoc else 0 end), sum(case when data between @data5 and @data4-1 then pret*stoc else 0 end),
	sum(case when data<@data5 then stoc else 0 end), sum(case when data<@data5 then pret*stoc else 0 end),
	max(loc_de_munca), max(cont)
from #stocuri
	where data<=@data1
	--group by Tip_gestiune, gestiune, cod, loc_de_munca, cont
	group by cod,tip_gestiune,'+
	(case @grupare	when 'G' then 'gestiune'
					when 'C' then 'Cont' --g.cont_contabil_specific		--> se grupa pe contul specific gestiunii in loc de contul din stocuri
					when 'M' then 'gestiune+''|''+loc_de_munca' end)
exec (@comanda_str)

if @tippret<>'s'
begin
	create table #preturi(cod varchar(20),nestlevel int)
	
	insert into #preturi
	select cod,@@NESTLEVEL
	from #stocvech
	group by cod

	exec CreazaDiezPreturi
	declare @px xml
	select @px=(select @categPret as categoriePret,@dData as data,@cGestiune as gestiune for xml raw)
	exec wIaPreturi @sesiune=null,@parXML=@px
	
	if @tippret='v'	--> pret vanzare
		update s set	valoare1=s.stoc1*isnull(pr.pret_vanzare,0),
						valoare2=s.stoc2*isnull(pr.pret_vanzare,0),
						valoare3=s.stoc3*isnull(pr.pret_vanzare,0),
						valoare4=s.stoc4*isnull(pr.pret_vanzare,0)
		from #stocvech s 
			inner join #preturi pr on pr.cod=s.cod
	
	if @tippret='t'	--> pe tip gestiune
		update s set	valoare1=s.stoc1*isnull(pr.pret_amanunt,0),
						valoare2=s.stoc2*isnull(pr.pret_amanunt,0),
						valoare3=s.stoc3*isnull(pr.pret_amanunt,0),
						valoare4=s.stoc4*isnull(pr.pret_amanunt,0)
		from #stocvech s 
			inner join #preturi pr on pr.cod=s.cod and s.tip_gestiune='A'
end
--*/
	/**	aducerea datelor finale catre raport */
select	/* max(s.gestiune) gestiune, max(s.Cont) --max(g.Cont_contabil_specific)
	as cont,
	max(case when isnull(g.tip_gestiune,'F')='F' and p.marca is not null then p.nume else g.denumire_gestiune end) as denumire_gestiune,
	s.cod,max(left(n.denumire,50)) denumire,max(n.um) um,  sum(s.Stoc1) Stoc1, sum(s.Valoare1) Valoare1, sum(s.Stoc2) Stoc2,sum(s.Valoare2) Valoare2,
	sum(s.Stoc3) Stoc3,sum(s.Valoare3) Valoare3,sum(s.Stoc4) Stoc4, sum(s.Valoare4) Valoare4, sum(s.Stoc5) Stoc5, sum(s.Valoare5) Valoare5,
	max(s.Locm) Locm, max(isnull(l.Denumire,'')) as nume_lm, 
	max(case when isnull(g.tip_gestiune,'F')='F' and p.marca is not null then 'F' else g.tip_gestiune end) as tip_gestiune
	*/
	s.gestiune gestiune, s.Cont --max(g.Cont_contabil_specific)
	as cont,
	(case when isnull(g.tip_gestiune,'F')='F' and p.marca is not null then p.nume else g.denumire_gestiune end) as denumire_gestiune,
	s.cod,left(n.denumire,50) denumire, n.um um, s.Stoc1 Stoc1, s.Valoare1 Valoare1, s.Stoc2 Stoc2, s.Valoare2 Valoare2,
	s.Stoc3 Stoc3, s.Valoare3 Valoare3, s.Stoc4 Stoc4, s.Valoare4 Valoare4, s.Stoc5 Stoc5, s.Valoare5 Valoare5,
	s.Locm Locm, isnull(l.Denumire,'') as nume_lm, 
	(case when isnull(g.tip_gestiune,'F')='F' and p.marca is not null then 'F' else g.tip_gestiune end) as tip_gestiune
from #stocvech s
  left outer join gestiuni g on s.gestiune=g.cod_gestiune and s.subunitate=g.subunitate
  left outer join nomencl n on s.cod=n.cod
  left join lm l on l.Cod=s.Locm
  left join personal p on p.Marca=s.gestiune
where (n.grupa like @grupa+'%' or @grupa is null)
	and (abs(stoc1)>0 or abs(stoc2)>0 or abs(stoc3)>0 or abs(stoc4)>0 or abs(stoc5)>0)
--group by s.grupare, s.Cod

if object_ID('tempdb..#stocvech') is not null drop table #stocvech
if object_ID('tempdb..#stocuri') is not null drop table #stocuri
if object_id('tempdb.dbo.#preturi') is not null drop table #preturi
