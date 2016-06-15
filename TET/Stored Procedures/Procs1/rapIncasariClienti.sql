--***
create procedure rapIncasariClienti(@sesiune varchar(50)='', @datajos datetime,@datasus datetime, @tert varchar(50)=null, @cod varchar(50)=null,
					@gestiune varchar(50)=null, @lm varchar(50)=null, @factura varchar(50)=null, @comanda varchar(50)=null,
				@Nivel1 varchar(2), @Nivel2 varchar(2), @Nivel3 varchar(2), @Nivel4 varchar(2), @Nivel5 varchar(2), @ordonare int,
				@grupaTerti varchar(20)=null,
				@grupa varchar(20)=null,	--> filtru pe grupa de nomenclator
				@puncteLivrare bit=0,	--> daca @puncteLivrare=1 gruparile pe terti vor fi de fapt grupari pe terti + puncte livrare
				@incasate int	--> 0 = toate, 1=doar incasate integral, 2=doar in sold
				)
as

	/**	Pregatire filtrare pe proprietati utilizatori*/
set transaction isolation level read uncommitted
declare @eroare varchar(max)
select @eroare=''
begin try
	declare @utilizator varchar(20), @eLmUtiliz int, @eGestUtiliz int
	select @utilizator=dbo.fIaUtilizator(@sesiune)
	declare @LmUtiliz table(valoare varchar(200))
	declare @GestUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
	insert into @LmUtiliz(valoare)
	--select valoare, cod_proprietate from fPropUtiliz() where valoare<>'' and cod_proprietate='LOCMUNCA'
	select cod from lmfiltrare where utilizator=@utilizator
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
	insert into @GestUtiliz(valoare, cod_proprietate)
	select valoare, cod_proprietate from fPropUtiliz(null) where valoare<>'' and cod_proprietate='GESTIUNE'
	set @eGestUtiliz=isnull((select max(1) from @GestUtiliz),0)

	select @grupa=@grupa+(case when isnull((select val_logica from par where tip_parametru='GE' and parametru='GRUPANIV'),0)=0 then '' else '%' end),
			@lm=@lm+'%'
		--> daca pentru grupele de nomenclator e activa setarea de grupe pe nivele se filtreaza cu 'like %'

	if object_id('tempdb.dbo.#incasari') is not null drop table #incasari
	if object_id('tempdb.dbo.#repPozdoc') is not null drop table #repPozdoc
	if object_id('tempdb.dbo.#deTrimis') is not null drop table #deTrimis
	if object_id('tempdb.dbo.#f') is not null drop table #f
	if object_id('tempdb.dbo.#1') is not null drop table #1
	if object_id('tempdb.dbo.#date_brute') is not null	drop table #date_brute
	if object_id('tempdb.dbo.#lunialfa') is not null drop table #lunialfa
	--> luare date din pozplin:
		select i.subunitate, rtrim(i.tert) tert, rtrim(i.factura) factura, i.numar, i.cont, i.loc_de_munca, i.data, sum(i.suma) incasare into #incasari from pozplin i
			where i.plata_incasare='IB' and (i.data between @datajos and @datasus) and (@lm is null or i.Loc_de_munca like @lm)
				and (i.factura = @factura or @factura is null) and (i.comanda = @comanda or @comanda is null)
				and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=i.Loc_de_munca))
				and i.subunitate='1'
			group by i.subunitate, i.tert, i.factura, i.numar, i.cont, i.loc_de_munca, i.data
	--> luare date din pozdoc:
		select	rtrim(isnull(p.tert,'')) as tert,  p.factura, lower(rtrim(isnull(p.cod,''))) as cod, isnull(p.gestiune,'') as gestiune,
				sum(isnull(p.cantitate,0)) as cantitate,
				sum(isnull(p.cantitate*p.pret_vanzare,0)) as pfTVA,
				sum(isnull(p.cantitate*p.pret_vanzare,0)+isnull(p.tva_deductibil,0)) as pcuTVA,
				sum(isnull(p.cantitate*p.pret_de_stoc,0)) as valCost, 
				sum(case when p.adaos=0 then 0 else isnull(p.cantitate*(p.pret_vanzare-p.pret_de_stoc),0) end) as adaos,
				(case when p.tip='AP' then d.gestiune_primitoare else '' end) as punct_livrare,
				max(p.tip) tip
			into #repPozdoc
			from pozdoc p 
				inner join doc d on p.subunitate=d.subunitate and p.tip=d.tip and p.data=d.data and p.numar=d.numar
			where (p.gestiune=@gestiune or @gestiune is null) 
					and p.tip in ('AP','AC','AS')
					and (@eGestUtiliz=0 or p.tip in ('RS','AS') or exists (select 1 from @GestUtiliz u where u.valoare=p.Gestiune))
					and exists (select 1 from #incasari i where p.subunitate=i.subunitate and p.tert=i.tert and p.factura=i.factura)
			group by p.tert, p.factura, p.cod, p.gestiune, (case when p.tip='AP' then d.gestiune_primitoare else '' end)

	--> unificare pozplin cu pozdoc:
		select	i.tert, rtrim(i.factura) factura, i.numar, i.cont, i.loc_de_munca, i.data, max(i.incasare) incasare,
				r.cod, r.gestiune, r.punct_livrare, max(r.cantitate) cantitate, max(r.pfTVA) pfTVA, max(r.pcuTVA) pcuTVA,
					max(r.valCost) valCost, max(r.adaos) adaos, max(tip) tip, max(i.incasare) as incasarePond, 0 incasate, 'IB' tipInc
		into #deTrimis
		from #incasari i left join #reppozdoc r on i.tert=r.tert and i.factura=r.factura
			cross apply(select sum(incasare) incasare from #incasari it where it.tert=r.tert and r.factura=it.factura)it
		group by i.subunitate, i.tert, i.factura, i.numar, i.cont, i.loc_de_munca, i.data, r.cod, r.gestiune, r.punct_livrare

	-->	repartizarea ponderata a incasarilor pe campurile pozdoc (cod, gestiune, grupa nomencl, punct livrare):
		update d set incasare=d.incasare*d.pcuTVA/d1.pcuTVA, incasate=(case when abs(incasare-d1.pcutva)>0.01 then 0 else 1 end)
		from #deTrimis d cross apply (select (case when sum(pcuTVA)=0 then 1 else sum(pcutva) end) pcuTVA from #repPozdoc d1 where d.tert=d1.tert and d.factura=d1.factura) d1

	-->	repartizarea ponderata a valorilor pozdoc pe documentele pozplin:
		update d set cantitate=d.cantitate*rapIncasare,
					pfTVA=d.pfTVA*rapIncasare,
					pcuTVA=d.pcuTVA*rapIncasare,
					valCost=d.valCost*rapIncasare,
					adaos=d.adaos*rapIncasare
		from #deTrimis d
			cross apply (select (case when sum(d1.incasare)>0 then convert(float,d.incasarePond)/sum(d1.incasare) else 0 end) rapIncasare
						from #incasari d1
						where d.tert=d1.tert and d.factura=d1.factura) d1
	--> iau denumirile lunilor:
		select luna, max(lunaalfa) lunaalfa into #lunialfa from fcalendar('2010-1-1','2010-12-1') group by luna
	--> luare informatii secundare (denumiri si altele care au legatura "indepartata" cu sumele si gruparile din raport)
	select isnull(month(p.data),0) as luna, isnull(p.data,'1/1/1901') as data, 
		rtrim(c.LunaAlfa)+' '+convert(varchar(4),
		YEAR(p.data)) as denluna, rtrim(p.tip) tip, rtrim(p.tert)+rtrim(isnull(' "'+i.identificator+'"','')) tert,
		rtrim(p.cod) cod,
		isnull(rtrim(n.denumire),'') as denumire, 
		isnull(rtrim(g.denumire),'') as grupa, rtrim(isnull(lm.cod ,'')) as loc,
		isnull(rtrim(lm.denumire),'') as locm, isnull(rtrim(t.denumire),'')+rtrim(isnull(' "'+i.descriere+'"','')) as client, 
		isnull(rtrim(ge.denumire_gestiune),'') as DenGes, rtrim(p.gestiune) gestiune, p.numar,p.cantitate,
		p.pfTVA, p.pcuTVA, p.valCost, p.adaos, greutate_specifica as greutate
		,rtrim(n.grupa) cod_grupa, p.factura, incasare, p.tipInc
	/*,isnull(p.factura,'') as factura, isnull(p.comanda,'') as comanda*/
	into #date_brute
	from #deTrimis p
		left outer join nomencl n on p.cod=n.cod
		left outer join grupe g on n.grupa=g.grupa
		left outer join terti t on t.subunitate='1' and p.tert=t.tert
		left join infotert i on @puncteLivrare=1 and t.subunitate=i.subunitate and t.tert=i.tert and identificator<>'' and p.punct_livrare=i.identificator
		left outer join gestiuni ge on p.gestiune=ge.cod_gestiune
		left outer join lm on p.loc_De_munca=lm.cod
		left join #lunialfa c on c.luna=month(p.data)
	where (p.tip='AC' or (p.tert=@tert or t.denumire like '%'+replace(isnull(@tert,' '),' ','%')+'%') and (@grupaTerti is null or t.Grupa=@grupaTerti)) 
		and (p.cod=@cod or n.denumire like '%'+replace(isnull(@cod,' '),' ','%')+'%')
		and (@grupa is null or n.grupa like @grupa)
		and (@incasate=0 or @incasate=1 and incasate=1 or @incasate=2 and incasate=0)

	-->	constructia nivelelor de grupare din raport:
		--> se definesc nivelele si etichetele atasate:
	select
		'Total' as niv0,
		rtrim(case @Nivel1 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(10),dateadd(d,1-day(data),data),102)
			when 'LO' then loc when 'DA' then convert(varchar(10),data,102) when 'GR' then cod_grupa
			when 'FA' then factura end) as niv1,
		rtrim(case @Nivel2 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(10),dateadd(d,1-day(data),data),102)
			when 'LO' then loc when 'DA' then convert(varchar(10),data,102) when 'GR' then cod_grupa
			when 'FA' then factura end) as niv2,
		rtrim(case @Nivel3 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(10),dateadd(d,1-day(data),data),102)
			when 'LO' then loc when 'DA' then convert(varchar(10),data,102) when 'GR' then cod_grupa
			 when 'FA' then factura end) as niv3,
		rtrim(case @Nivel4 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(10),dateadd(d,1-day(data),data),102)
			when 'LO' then loc when 'DA' then convert(varchar(10),data,102) when 'GR' then cod_grupa
			when 'FA' then factura end) as niv4,
		rtrim(case @Nivel5 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(10),dateadd(d,1-day(data),data),102)
			when 'LO' then loc when 'DA' then convert(varchar(10),data,102) when 'GR' then cod_grupa
			when 'FA' then factura end) as niv5,
		rtrim(tipInc)+' '+rtrim(numar)+' '+convert(varchar(10),data,103) as niv6,	
		cantitate, greutate, pfTVA, isnull(pcuTVA,0) pcuTVA, valCost, adaos, incasare,
		'Total' as nume0,
		(case @Nivel1 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna
			when 'LO' then locm when 'DA' then convert(varchar(10),data,103) when 'GR' then grupa when 'FA' then factura end) as nume1,
		(case @Nivel2 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna
			when 'LO' then locm when 'DA' then convert(varchar(10),data,103) when 'GR' then grupa when 'FA' then factura end) as nume2,
		(case @Nivel3 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna
			when 'LO' then locm when 'DA' then convert(varchar(10),data,103) when 'GR' then grupa when 'FA' then factura end) as nume3,
		(case @Nivel4 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna
			when 'LO' then locm when 'DA' then convert(varchar(10),data,103) when 'GR' then grupa when 'FA' then factura end) as nume4,
		(case @Nivel5 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna
			when 'LO' then locm when 'DA' then convert(varchar(10),data,103) when 'GR' then grupa when 'FA' then factura end) as nume5
		into #1
	from #date_brute

	select 'Total' as tip_nivel, niv0 as cod,'' as parinte,sum(cantitate) as cantitate, sum(greutate) as greutate, sum(pfTVA) as pfTVA, 
			sum(pcuTVA) as pcuTVA, SUM(valCost) as valCost, SUM(adaos) as adaos, sum(incasare) incasare, 0 as nivel,
			max(nume0) as nume, space(100) as ordine,
			'' niv1, '' nume1, 0 incasaregr, 0 topgr	--> ultimele 4 campuri sunt pt grafic
		into #f 
				from #1 where niv0 is not null group by niv0 union all
	select @Nivel1 as tip_nivel, niv1 as cod,niv0+'|' as parinte,sum(cantitate) as cantitate, sum(greutate) as greutate, sum(pfTVA) as pfTVA, 
			sum(pcuTVA) as pcuTVA, SUM(valCost) as valCost, SUM(adaos) as adaos, sum(incasare) incasare, 1 as nivel, 
			max(nume1)+(case when @nivel1 in ('TE','CO','GE','LO','GR') then ' ('+niv1+')' else '' end) as nume, '' as ordine,
			niv1 niv1, max(nume1) nume1, sum(incasare) incasaregr, row_number() over (order by sum(incasare) desc) as topgr
		from #1 where niv1 is not null group by niv1,niv0 union all
	select @Nivel2 as tip_nivel, niv2, niv1+'|'+niv0+'|' as parinte,sum(cantitate) as cantitate, sum(greutate) as greutate, sum(pfTVA) as pfTVA, 
			sum(pcuTVA) as pcuTVA, SUM(valCost) as valCost, SUM(adaos) as adaos, sum(incasare) incasare, 2,
			max(nume2)+(case when @nivel2 in ('TE','CO','GE','LO','GR') then ' ('+niv2+')' else '' end), '' as ordine,
			'' niv1, '' nume1, 0 incasaregr, 0 topgr
		from #1 where niv2 is not null group by niv2,niv1,niv0 union all
	select @Nivel3 as tip_nivel, niv3, niv2+'|'+niv1+'|'+niv0+'|' as parinte,sum(cantitate) as cantitate, sum(greutate) as greutate, sum(pfTVA) as pfTVA, 
			sum(pcuTVA) as pcuTVA, SUM(valCost) as valCost, SUM(adaos) as adaos, sum(incasare) incasare, 3,
			max(nume3)+(case when @nivel3 in ('TE','CO','GE','LO','GR') then ' ('+niv3+')' else '' end), '' as ordine,
			'' niv1, '' nume1, 0 incasaregr, 0 topgr
		from #1 where niv3 is not null group by niv3,niv2,niv1,niv0 union all
	select @Nivel4 as tip_nivel, niv4, niv3+'|'+niv2+'|'+niv1+'|'+niv0+'|' as parinte,sum(cantitate) as cantitate, sum(greutate) as greutate, sum(pfTVA) as pfTVA, 
			sum(pcuTVA) as pcuTVA, SUM(valCost) as valCost, SUM(adaos) as adaos, sum(incasare) incasare, 4,
			max(nume4)+(case when @nivel4 in ('TE','CO','GE','LO','GR') then ' ('+niv4+')' else '' end), '' as ordine,
			'' niv1, '' nume1, 0 incasaregr, 0 topgr
		from #1 where niv4 is not null group by niv4,niv3,niv2,niv1,niv0 union all
	select @Nivel5 as tip_nivel, niv5, niv4+'|'+niv3+'|'+niv2+'|'+niv1+'|'+niv0+'|' as parinte,sum(cantitate) as cantitate, sum(greutate) as greutate, sum(pfTVA) as pfTVA, 
			sum(pcuTVA) as pcuTVA, SUM(valCost) as valCost, SUM(adaos) as adaos, sum(incasare) incasare, 5,
			max(nume5)+(case when @nivel5 in ('TE','CO','GE','LO','GR') then ' ('+niv5+')' else '' end), '' as ordine,
			'' niv1, '' nume1, 0 incasaregr, 0 topgr
		from #1 where niv5 is not null group by niv5,niv4,niv3,niv2,niv1,niv0 union all
	select '' as tip_nivel, niv6, isnull(niv5+'|','')+isnull(niv4+'|','')+isnull(niv3+'|','')+isnull(niv2+'|','')+niv1+'|'+niv0+'|' as parinte, 
			cantitate, greutate, pfTVA, pcuTVA, valCost, adaos, incasare incasare, 6,niv6, '' as ordine,
			'' niv1, '' nume1, 0 incasaregr, 0 topgr
		from #1
	--order by (case when @alfabetic=1 then cod else nume end)

	update #f set ordine=(case when tip_nivel in('DA','LU','FA') or @ordonare=1 then cod else nume end)

	select cod, parinte, cantitate, greutate, pfTVA, pcuTVA, valCost, adaos, incasare, nivel, nume, tip_nivel, ordine,
			(case when topgr<10 then niv1 else 'Altii' end) niv1, (case when topgr<10 then nume1 else 'Altii' end) nume1, incasaregr, (case when topgr<10 then topgr else 10 end) topgr
		from #f 
		order by ordine
end try
begin catch
	select @eroare=error_message()+' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

if object_id('tempdb.dbo.#incasari') is not null drop table #incasari
if object_id('tempdb.dbo.#repPozdoc') is not null drop table #repPozdoc
if object_id('tempdb.dbo.#deTrimis') is not null drop table #deTrimis
if object_id('tempdb.dbo.#f') is not null drop table #f
if object_id('tempdb.dbo.#1') is not null drop table #1
if object_id('tempdb.dbo.#date_brute') is not null	drop table #date_brute
if object_id('tempdb.dbo.#lunialfa') is not null drop table #lunialfa

if len(@eroare)>0
select @eroare as nume, '<EROARE>' as cod
