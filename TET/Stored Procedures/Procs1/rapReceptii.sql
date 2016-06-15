--***
Create procedure rapReceptii (@datajos datetime,@datasus datetime,@tert varchar(50)=null, @pref_tert varchar(50)=null, @cod varchar(50)=null,
					@pref_cod varchar(50)=null, @gestiune varchar(50)=null, @factura varchar(50)=null, @comanda varchar(50)=null
				,@Nivel1 varchar(2) ,@Nivel2 varchar(2) ,@Nivel3 varchar(2) ,@Nivel4 varchar(2), @Nivel5 varchar(2), @alfabetic int,
				@grupa varchar(20)=null, @locatie varchar(200)=null)
as
/*	test:
declare @datajos datetime,@datasus datetime,@tert nvarchar(4000),@pref_tert nvarchar(4000),@cod nvarchar(4000),@pref_cod nvarchar(4000),@gestiune nvarchar(4000),@factura nvarchar(4000),@comanda nvarchar(4000)
		,@Nivel1 varchar(2) ,@Nivel2 varchar(2) ,@Nivel3 varchar(2) ,@Nivel4 varchar(2), @Nivel5 varchar(2), @alfabetic int
select @datajos='2010-07-01 00:00:00',@datasus='2010-07-26 00:00:00',@tert='24800108',@pref_tert=NULL,@cod=null,@pref_cod=NULL,
		@gestiune=NULL,@factura=NULL,@comanda=NULL
		,@Nivel1='da', @Nivel2='CO', @Nivel3='LU', @Nivel4='TE', @Nivel5=null, @alfabetic=1
--*/
	/**	Pregatire filtrare pe proprietati utilizatori*/
set transaction isolation level read uncommitted
declare @utilizator varchar(20)
select @utilizator=dbo.fIaUtilizator('')
declare @eLmUtiliz int,@eGestUtiliz int
declare @LmUtiliz table(valoare varchar(200))
declare @GestUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
insert into @LmUtiliz(valoare)
select cod from lmfiltrare  l where l.utilizator=@utilizator
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
insert into @GestUtiliz(valoare, cod_proprietate)
select valoare, cod_proprietate from fPropUtiliz(null) where valoare<>'' and cod_proprietate='GESTIUNE'
set @eGestUtiliz=isnull((select max(1) from @GestUtiliz),0)

select @grupa=@grupa+(case when isnull((select val_logica from par where tip_parametru='GE' and parametru='GRUPANIV'),0)=0 then '' else '%' end)
	--> daca pentru grupele de nomenclator e activa setarea de grupe pe nivele se filtreaza cu 'like %'
	
if object_id('tempdb.dbo.#date_brute') is not null drop table #date_brute
if object_id('tempdb.dbo.#1') is not null drop table #1
if object_id('tempdb.dbo.#f') is not null  drop table #f

select isnull(month(p.data),0) as luna, isnull(p.data,'1/1/1901') as data, 
	isnull(rtrim(c.lunaalfa),'') as denluna, isnull(p.tip,'') as tip ,rtrim(isnull(p.tert,'')) as tert,
	rtrim(isnull(p.cod,'')) as cod, isnull(rtrim(n.denumire),'') as denumire, isnull(rtrim(g.denumire),'') as grupa, 
	rtrim(isnull(lm.cod ,'')) as loc,
	isnull(rtrim(lm.denumire),'') as locm, isnull(rtrim(t.denumire),'') as client, 
	isnull(rtrim(ge.denumire_gestiune),'') as DenGes,
	rtrim(isnull(p.gestiune,'')) as gestiune, isnull(p.numar,'') as numar,isnull(p.cantitate,0) as cantitate, 
	(case when p.valuta<>'' then isnull(p.cantitate*p.pret_valuta*p.curs+p.TVA_deductibil,0) else isnull(p.cantitate*p.pret_valuta+p.TVA_deductibil,0) end) as pcuTVA,
	isnull(p.cantitate*p.pret_de_stoc,0) as valoare_stoc, 
	--isnull(p.cantitate*(p.pret_vanzare-p.pret_de_stoc),0) as adaos
	isnull(p.cantitate*p.pret_vanzare,0) as pret_vanzare,
	(case when p.valuta<>'' then isnull(p.cantitate*p.pret_valuta*p.curs,0) else isnull(p.cantitate*p.pret_valuta,0) end) as valoare_furn,
	rtrim(n.grupa) cod_grupa, rtrim(left(p.comanda,20)) comanda, rtrim(isnull(co.descriere,'')) as den_comanda
into #date_brute
from pozdoc p
	left outer join nomencl n on p.cod=n.cod
	left outer join grupe g on n.grupa=g.grupa
	left outer join terti t on p.tert=t.tert
	left outer join gestiuni ge on p.gestiune=ge.cod_gestiune
	left outer join lm on p.loc_De_munca=lm.cod
	left join calstd c on p.data= c.data
	left join comenzi co on '1'=co.subunitate and left(p.comanda,20)=co.comanda
where p.tip in ('RM','RS') and p.data between @datajos and @datasus 
	and (p.tert=@tert or @tert is null and t.denumire like '%'+replace(isnull(@pref_tert,' '),' ','%')+'%') 
	and (p.cod=@cod or @cod is null and n.denumire like '%'+replace(isnull(@pref_cod,' '),' ','%')+'%')
	and (p.gestiune = @gestiune or @gestiune is null) and (p.factura = @factura or @factura is null)
	and (p.comanda = @comanda or @comanda is null)
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca))
	and (@eGestUtiliz=0 or p.tip in ('RS','AS') or exists (select 1 from @GestUtiliz u where u.valoare=p.Gestiune))
	and (@grupa is null or n.grupa like @grupa)
	and (@locatie is null or p.locatie=@locatie)
order by luna

select	-- construiesc recursiv gruparile pentru a nu mai avea probleme pe Rep 2008
	'Total' niv0,
	(case @Nivel1 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(10),dateadd(d,1-day(data),data),102)
		when 'LO' then loc when 'DA' then convert(varchar(10),data,102) when 'GR' then cod_grupa when 'CM' then comanda end) as niv1,
	(case @Nivel2 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(10),dateadd(d,1-day(data),data),102)
		when 'LO' then loc when 'DA' then convert(varchar(10),data,102) when 'GR' then cod_grupa when 'CM' then comanda end) as niv2,
	(case @Nivel3 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(10),dateadd(d,1-day(data),data),102)
		when 'LO' then loc when 'DA' then convert(varchar(10),data,102) when 'GR' then cod_grupa when 'CM' then comanda end) as niv3,
	(case @Nivel4 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(10),dateadd(d,1-day(data),data),102)
		when 'LO' then loc when 'DA' then convert(varchar(10),data,102) when 'GR' then cod_grupa when 'CM' then comanda end) as niv4,
	(case @Nivel5 when 'TE' then tert when 'CO' then cod when 'GE' then gestiune when 'LU' then convert(varchar(10),dateadd(d,1-day(data),data),102)
		when 'LO' then loc when 'DA' then convert(varchar(10),data,102) when 'GR' then cod_grupa when 'CM' then comanda end) as niv5,
	tip+' '+rtrim(numar)+' '+convert(varchar(10),data,103) as niv6,
	--luna, denluna, tert, client, cod, denumire, gestiune, DenGes, loc, locm
	data, tip, grupa, numar, cantitate, pcuTVA, valoare_stoc, pret_vanzare, valoare_furn,
	'Total' nume0,
	(case @Nivel1 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna
		when 'LO' then locm when 'DA' then convert(varchar(10),data,103) when 'GR' then grupa when 'CM' then den_comanda end) as nume1,
	(case @Nivel2 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna
		when 'LO' then locm when 'DA' then convert(varchar(10),data,103) when 'GR' then grupa when 'CM' then den_comanda end) as nume2,
	(case @Nivel3 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna
		when 'LO' then locm when 'DA' then convert(varchar(10),data,103) when 'GR' then grupa when 'CM' then den_comanda end) as nume3,
	(case @Nivel4 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna
		when 'LO' then locm when 'DA' then convert(varchar(10),data,103) when 'GR' then grupa when 'CM' then den_comanda end) as nume4,
	(case @Nivel5 when 'TE' then client when 'CO' then denumire when 'GE' then denges when 'LU' then denluna
		when 'LO' then locm when 'DA' then convert(varchar(10),data,103) when 'GR' then grupa when 'CM' then den_comanda end) as nume5
	into #1
from #date_brute

select 'Total' tip_nivel, niv0 as cod,'' as parinte,
		sum(cantitate) cantitate, sum(valoare_furn) valoare_furn, sum(valoare_stoc) valoare_stoc, sum(pcuTVA) pcuTVA,
		0 as nivel, max(nume0) as nume, space(100) as ordine,
		'' niv1, '' nume1, 0 valoare_stoc_gr, 0 topgr	--> ultimele 4 campuri sunt pt grafic
	into #f 
	from #1 where niv0 is not null group by niv0 union all
select @nivel1 tip_nivel, niv1 as cod,niv0+'|' as parinte,sum(cantitate) cantitate, sum(valoare_furn) valoare_furn, sum(valoare_stoc) valoare_stoc, sum(pcuTVA) pcuTVA,
		1 as nivel, max(nume1) as nume, '' as ordine,
		niv1 niv1, max(case when @nivel1='CM' then niv1+' - ' else '' end)+max(nume1) nume1, sum(valoare_stoc) valoare_stoc_gr, row_number() over (order by sum(valoare_stoc) desc) topgr
	from #1 where niv1 is not null group by niv1,niv0 union all
select @nivel2 tip_nivel, niv2, niv1+'|'+niv0+'|' as parinte,sum(cantitate) cantitate, sum(valoare_furn) valoare_furn, sum(valoare_stoc) valoare_stoc, sum(pcuTVA) pcuTVA, 2, max(nume2), '' as ordine,
		'' niv1, '' nume1, 0 valoare_stoc_gr, 0 topgr
	from #1 where niv2 is not null group by niv2,niv1,niv0 union all
select @nivel3 tip_nivel, niv3, niv2+'|'+niv1+'|'+niv0+'|' as parinte,sum(cantitate) cantitate, sum(valoare_furn) valoare_furn, sum(valoare_stoc) valoare_stoc, sum(pcuTVA) pcuTVA, 3,max(nume3), '' as ordine,
		'' niv1, '' nume1, 0 valoare_stoc_gr, 0 topgr
	from #1 where niv3 is not null group by niv3,niv2,niv1,niv0 union all
select @nivel4 tip_nivel, niv4, niv3+'|'+niv2+'|'+niv1+'|'+niv0+'|' as parinte, sum(cantitate) cantitate, sum(valoare_furn) valoare_furn, sum(valoare_stoc) valoare_stoc, sum(pcuTVA) pcuTVA, 4, MAX(nume4), '' as ordine,
		'' niv1, '' nume1, 0 valoare_stoc_gr, 0 topgr
	from #1 where niv4 is not null group by niv4,niv3,niv2,niv1,niv0 union all
--select niv5, niv4 as parinte,0, 0 , 0 , 0 , 5,MAX(nume5) from #1 where niv5 is not null group by niv5,niv4,niv3,niv2,niv1 union all
select '' as tip_nivel, niv6, isnull(niv4+'|','')+isnull(niv3+'|','')+isnull(niv2+'|','')+isnull(niv1+'|','')+isnull(niv0+'|','') as parinte, 
		cantitate, valoare_furn, valoare_stoc, pcuTVA
		,6,rtrim(tip)+' '+rtrim(numar)+' '+convert(varchar(10),data,102) --,data, tip, grupa, numar 
		, '' as ordine, '' niv1, '' nume1, 0 valoare_stoc_gr, 0 topgr
	from #1

--> ordinea nu poate fi pe denumire pentru 'DA'=data, 'LU=luna, 'FA'=factura
update #f set ordine=(case when tip_nivel in ('DA','LU','FA') or @alfabetic=0 then cod else nume end)

select cod, parinte, cantitate, valoare_furn, valoare_stoc, pcuTVA, nivel, rtrim(nume)+(case when nivel<6 and nivel>0 and tip_nivel<>'DA' then ' ('+rtrim(cod)+')' else '' end) as nume,
		ordine, (case when topgr<10 then niv1 else 'Altii' end) niv1, (case when topgr<10 then nume1 else 'Altii' end) nume1, valoare_stoc_gr, (case when topgr<10 then topgr else 10 end) topgr
		--into  tmpluci 
		from #f 
		order by nivel, ordine

if object_id('tempdb.dbo.#date_brute') is not null drop table #date_brute
if object_id('tempdb.dbo.#1') is not null drop table #1
if object_id('tempdb.dbo.#f') is not null  drop table #f
--*/
