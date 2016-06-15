--***
create procedure rapMFbal_conturi @datajos datetime,@datasus datetime, @cont varchar(40)='', 
	@lm varchar(9)='', @lmExcep char(10)='', @nr_inventar varchar(20)=null,
	@tipPatrimoniu varchar(1)=null, --> '3'=null=Toate, '2'=''=Privat, '1'=Public
	@tipImobilizare varchar(1)=1,	--> tip imobilizare:	1=M. fixe, 2=Obiecte inventar, 3=MF dupa casare
	@tipActiv smallint=0		--> Tip active (categoria 7) 0=toate, 1=Corporale, 2=Necorporale
 as

set transaction isolation level read uncommitted
declare @sub char(9), @contcls8 varchar(40)

set @sub = (select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO')
set @contcls8 = isnull((select rtrim(val_alfanumerica) from par where tip_parametru='MF' and parametru='CTAMGRNU'),'')
if @contcls8='' set @contcls8='8045'
set @lmExcep=isnull(rtrim(@lmExcep),'')+'%'

if object_id('tempdb.dbo.#dens') is not null drop table #dens
if object_id('tempdb.dbo.#fisamf') is not null drop table #fisamf
if object_id('tempdb.dbo.#coresp_transferuri') is not null drop table #coresp_transferuri
if object_id('tempdb.dbo.#amortizari_transferuri') is not null drop table #amortizari_transferuri
if object_id('tempdb.dbo.#conturi_amortizare') is not null drop table #conturi_amortizare

select @tipPatrimoniu=(case when @tipPatrimoniu='3' then null when @tipPatrimoniu='2' then '' else @tipPatrimoniu end)

--< Filtrare pe locuri de munca pe utilizatori
	declare @utilizator varchar(20), @eLmUtiliz int
	select @utilizator=dbo.fIaUtilizator('')
	declare @LmUtiliz table(valoare varchar(200))
	set @eLmUtiliz=0
	insert into @LmUtiliz(valoare)
		select cod from lmfiltrare where utilizator=@utilizator
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
--/>
-- <prefiltrari
	select mf.numar_de_inventar, isnull(m.tert,mf.Tip_amortizare) as tipPatrimoniu, mf.serie as tipImobilizare, 
		mf.Cod_de_clasificare as cont_amortizare	-- contul de amortizare s-a mutat in fisamf
	into #dens
	from mfix mf 
		left join mismf m on m.subunitate=@sub and mf.Numar_de_inventar=m.Numar_de_inventar
			and m.tip_miscare='MTP' AND m.Data_miscarii=(
						select max(ma.Data_miscarii) from mismf ma where ma.subunitate='1'
							and m.Numar_de_inventar=ma.Numar_de_inventar and ma.tip_miscare='MTP'
							AND ma.Data_lunii_de_miscare<=@datasus)
	where mf.subunitate='dens'
		and (@nr_inventar is null or mf.numar_de_inventar = @nr_inventar)
	
	create index inddens on #dens(numar_de_inventar)
		
	select f.* into #fisamf
		from fisamf f
			left join #dens d on d.numar_de_inventar=f.Numar_de_inventar
		where	--(@cont is null or f.cont_mijloc_fix like @cont) and 
			(@eLmUtiliz=0 or exists(select 1 from @LmUtiliz u where u.valoare=f.Loc_de_munca))
			and (@lmExcep='%' or f.Loc_de_munca not like @lmExcep)
			and (@nr_inventar is null or f.numar_de_inventar = @nr_inventar)
			and (@tipImobilizare='1' and d.tipImobilizare not in ('O','C') or d.tipImobilizare=@tipImobilizare)
			and (@tipPatrimoniu is null or d.tipPatrimoniu=@tipPatrimoniu)
			and (@tipActiv=0 or @tipActiv=1 and f.Categoria<>'7' or @tipActiv=2 and f.Categoria='7')

	CREATE /*UNIQUE */CLUSTERED INDEX Subunitate_Nrinv_Perioada ON #fisaMF
		(
			Subunitate ASC,
			Numar_de_inventar ASC,
			Data_lunii_operatiei ASC,
			Felul_operatiei ASC
		)
		
	select m.numar_de_inventar
		,max(isnull(f6.loc_de_munca,f1.loc_de_munca)) lm_predator
		,max(f.loc_de_munca) lm_primitor
		/*	Daca exista modificare in luna si LM modificare=LM primitor de transfer (modificare ulterioara transferului) atunci se transfera val. de inventar anterioara modificarii. */
		,max(case when isnull(fm.Loc_de_munca,'')<>'' and isnull(fm.Loc_de_munca,'')=isnull(f.Loc_de_munca,'') then f1.valoare_de_inventar else f.valoare_de_inventar end) valoare_de_inventar
		,max(f.cont_mijloc_fix) cont
		,isnull(max(f.Cont_amortizare),isnull((select top 1 convert(varchar(40),gestiune_primitoare) from mismf mm 
				where mm.subunitate=@sub and tip_miscare in ('MMF','MTO') and 
					data_lunii_de_miscare>=@datajos and mm.numar_de_inventar=m.numar_de_inventar 
				order by data_miscarii),'')) as cont_amortizare
		into #coresp_transferuri
	FROM mismf m
		inner join fisamf f on f.subunitate=m.subunitate and f.felul_operatiei='1' and f.data_lunii_operatiei=m.data_lunii_de_miscare and m.numar_de_inventar=f.numar_de_inventar
		left join fisamf f6 on f6.subunitate=m.subunitate and f6.felul_operatiei='6' and f6.data_lunii_operatiei=m.data_lunii_de_miscare and f6.numar_de_inventar=m.numar_de_inventar
		inner join fisamf f1 on f1.subunitate=m.subunitate and m.numar_de_inventar=f1.numar_de_inventar and f1.Data_lunii_operatiei<=f.Data_lunii_operatiei and f1.loc_de_munca<>f.loc_de_munca
			and not exists (select 1 from fisamf f2 where f2.subunitate=m.subunitate and f1.numar_de_inventar=f2.numar_de_inventar and f2.Data_lunii_operatiei<f.data_lunii_operatiei and f2.Data_lunii_operatiei>f1.data_lunii_operatiei)
		left join #dens d on d.Numar_de_inventar=m.Numar_de_inventar
		left outer join fisamf fm on fm.subunitate=m.subunitate and fm.felul_operatiei='4' and fm.data_lunii_operatiei=m.data_lunii_de_miscare and m.numar_de_inventar=fm.numar_de_inventar
	where m.subunitate=@sub and left(m.Tip_miscare,1)='T' and m.Data_lunii_de_miscare between @datajos and @datasus 
			and m.Cont_corespondent<>'' 
			and (@eLmUtiliz=0 or exists(select 1 from @LmUtiliz u where u.valoare=f.Loc_de_munca or u.valoare=f1.loc_de_munca))
			and (@lmExcep='%' or f.Loc_de_munca not like @lmExcep or f1.Loc_de_munca not like @lmExcep)
			and (@nr_inventar is null or f.numar_de_inventar = @nr_inventar)
			and (isnull(@lm,'')='' or f1.loc_de_munca like @lm+'%' or f.loc_de_munca like @lm+'%')
			--and (@cont is null or f.cont_mijloc_fix like @cont or xd.cod_de_clasificare like @cont)
			and (@tipImobilizare='1' and d.tipImobilizare not in ('O','C') or d.tipImobilizare=@tipImobilizare)
			and (@tipPatrimoniu is null or d.tipPatrimoniu=@tipPatrimoniu)
			and (@tipActiv=0 or @tipActiv=1 and f.Categoria<>'7' or @tipActiv=2 and f.Categoria='7')
	group by m.numar_de_inventar
		
	--select * from #coresp_transferuri

	select	m.numar_de_inventar
			,sum(case when felul_operatiei='6' 
				then d.valoare_amortizata-d.Valoare_amortizata_cont_8045-d.amortizare_lunara+d.amortizare_lunara_cont_8045
				else 0 end)
			as [valoare intrari]
			,sum(case when felul_operatiei='6' 
				then d.Valoare_amortizata_cont_8045-d.amortizare_lunara_cont_8045
				else 0 end)
			as [valoare intrari 8045]
			,0 as [valoare iesiri],0 as [valoare iesiri 8045]
			,max(lm_primitor) lm, m.cont_amortizare 
	into #amortizari_transferuri
	FROM #coresp_transferuri m inner join fisamf d on m.numar_de_inventar=d.numar_de_inventar
			and Felul_operatiei='6' and lm_predator=d.loc_de_munca
		where d.subunitate=rtrim(@sub) and d.data_lunii_operatiei between @datajos and @datasus 
			and (isnull(@lm,'')='' and @eLmUtiliz=0 and 1=0	--	daca fara loc de munca (filtre/proprietati) nu trebuie creat rulaj
				or isnull(@lm,'')<>'' and lm_primitor like rtrim(@lm)+'%' 
				or @eLmUtiliz>0 and exists(select 1 from @LmUtiliz u where u.valoare=lm_primitor))
			/*and (isnull(@lm,'')='' or lm_primitor like rtrim(@lm)+'%')
			and (isnull(@lm,'')<>'' or @eLmUtiliz=0 or exists(select 1 from @LmUtiliz u where u.valoare=lm_primitor))*/
			--and (isnull(@lm,'')='' or m.lm_predator like @lm+'%')
		group by m.numar_de_inventar, m.cont_amortizare
	union all
	select	m.numar_de_inventar, 0 as [valoare intrari], 0 as [valoare intrari 8045]		
			,sum(case when felul_operatiei='6' 
				then d.valoare_amortizata-d.Valoare_amortizata_cont_8045-d.amortizare_lunara+d.amortizare_lunara_cont_8045 
				else 0 end)
			as [valoare iesiri]	
			,sum(case when felul_operatiei='6' 
				then d.Valoare_amortizata_cont_8045-d.amortizare_lunara_cont_8045 
				else 0 end)
			as [valoare iesiri 8045]	
			,max(lm_predator) lm, m.cont_amortizare
	FROM #coresp_transferuri m inner join fisamf d on m.numar_de_inventar=d.numar_de_inventar
				and Felul_operatiei='6' and lm_predator=d.loc_de_munca
		where d.subunitate=rtrim(@sub) and d.data_lunii_operatiei between @datajos and @datasus 
			and (isnull(@lm,'')='' and @eLmUtiliz=0 and 1=0	--	daca fara loc de munca (filtre/proprietati) nu trebuie creat rulaj 
				or isnull(@lm,'')<>'' and lm_predator like rtrim(@lm)+'%' 
				or @eLmUtiliz>0 and exists(select 1 from @LmUtiliz u where u.valoare=lm_predator))
			/*(isnull(@lm,'')='' or lm_predator like rtrim(@lm)+'%')
			and (isnull(@lm,'')<>'' or @eLmUtiliz=0 or exists(select 1 from @LmUtiliz u where u.valoare=lm_predator))*/
			--and (isnull(@lm,'')='' or m.lm_primitor like @lm+'%')
		group by m.numar_de_inventar, m.cont_amortizare

	 select isnull(f.Cont_amortizare,isnull(convert(varchar(40),mm.gestiune_primitoare),'')) as cont,
		m.numar_de_inventar into #conturi_amortizare--,mm.gestiune_primitoare,m.cod_de_clasificare
		From mfix m 
			left join fisamf f on f.subunitate=@sub and f.felul_operatiei='1' and f.data_lunii_operatiei=@datasus and m.numar_de_inventar=f.numar_de_inventar
			left join mismf mm on m.numar_de_inventar=mm.numar_de_inventar
				and tip_miscare in ('MMF','MTO') and data_lunii_de_miscare>=@datajos 
				and mm.subunitate=@sub 
				and not exists (select 1 from mismf mm2
				where mm2.numar_de_inventar=mm.numar_de_inventar and mm2.subunitate=@sub 
					and tip_miscare in ('MMF','MTO') and mm2.data_lunii_de_miscare>=@datajos
					and mm2.data_lunii_de_miscare<mm.data_lunii_de_miscare
					)
	where m.subunitate='dens'
		and (@tipImobilizare='1' and m.Serie not in ('O','C') or m.Serie=@tipImobilizare)
	--select * from #amortizari_transferuri

-- /prefiltrari>

SELECT rtrim(Cont) cont,rtrim(max([Denumire cont])) as [Denumire cont],
	sum([Valoare inceput perioada]) as [Valoare inceput perioada],
	sum([Valoare intrari]) as [Valoare intrari],
	sum([Valoare iesiri]) as [Valoare iesiri],
	sum([Valoare modificari]) as [Valoare modificari],
	sum((isnull([Valoare inceput perioada],0)+isnull([Valoare intrari],0)-
	isnull([Valoare iesiri],0)+isnull([Valoare modificari],0))) as [Valoare sfarsit perioada],
	sum((isnull([Valoare intrari],0)-isnull([Valoare iesiri],0)+isnull([Valoare modificari],0))) 
		as [Rulaj perioada], tip_cont
FROM (
SELECT a.cont,
	(select b.denumire_cont from conturi b where a.cont=b.cont and b.subunitate=rtrim(@sub)) 
		as [Denumire cont]
	,isnull((select sum(c.valoare_de_inventar) from #fisamf c where c.subunitate=rtrim(@sub) 
		and a.numar_de_inventar=c.numar_de_inventar  and a.cont=c.cont_mijloc_fix 
		and c.felul_operatiei='1' and data_lunii_operatiei=dateadd(d,-1,@datajos)
		and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0) 
		as [Valoare inceput perioada]
	,isnull((select sum(d.valoare_de_inventar) from #fisamf d where d.subunitate=rtrim(@sub) 
		and a.numar_de_inventar=d.numar_de_inventar  and a.cont=d.cont_mijloc_fix 
		and d.felul_operatiei='3' and data_lunii_operatiei between @datajos and @datasus
		and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0) as [Valoare intrari]
	,isnull((select sum(e.valoare_de_inventar) from #fisamf e where e.subunitate=rtrim(@sub) 
		and a.numar_de_inventar=e.numar_de_inventar  and a.cont=e.cont_mijloc_fix 
		and e.felul_operatiei='5' and data_lunii_operatiei between @datajos and @datasus
		and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0) as [Valoare iesiri]
	,isnull((select sum(f.diferenta_de_valoare) from mismf f where f.subunitate=rtrim(@sub) 
		and left(f.tip_miscare,1)='M' and f.data_lunii_de_miscare between @datajos and @datasus 
		and a.numar_de_inventar=f.numar_de_inventar and exists (select 1 from #fisamf g where 
		g.subunitate=rtrim(@sub) and g.felul_operatiei='4' 
		and g.numar_de_inventar=f.numar_de_inventar and a.cont=g.cont_mijloc_fix 
		and data_lunii_operatiei between @datajos and @datasus
		and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%'))),0) as [Valoare modificari],
	'conturi mijloace fixe' as tip_cont
FROM (select distinct numar_de_inventar, cont_mijloc_fix as cont from #fisamf where subunitate=rtrim(@sub) and felul_operatiei='1' 
	--and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')
	) a 
UNION ALL	
	SELECT m.cont as Cont
		,(select top 1 b.denumire_cont from conturi b
			where b.cont=m.cont
					and b.subunitate=rtrim(@sub)) as [Denumire cont]
		,isnull((select sum(c.valoare_amortizata-c.valoare_amortizata_cont_8045) from #fisamf c 
			where c.subunitate=rtrim(@sub) and c.felul_operatiei='1' and m.numar_de_inventar=c.numar_de_inventar
					and data_lunii_operatiei=dateadd(d,-1,@datajos) and m.cont=c.cont_amortizare
					and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0) as [Valoare inceput perioada]
		,isnull((select sum(d.amortizare_lunara-d.amortizare_lunara_cont_8045) from #fisamf d
			where d.subunitate=rtrim(@sub) and d.felul_operatiei='1' 
			and data_lunii_operatiei between @datajos and @datasus and m.numar_de_inventar=d.numar_de_inventar
			and m.cont=d.cont_amortizare
			and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0)
		 +isnull((select sum(h.valoare_amortizata-h.Valoare_amortizata_cont_8045) from #fisamf h 
			where h.subunitate=rtrim(@sub) and h.felul_operatiei='3' 
			and data_lunii_operatiei between @datajos and @datasus and m.numar_de_inventar= h.numar_de_inventar
			and m.cont=h.cont_amortizare
			and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0) as [Valoare intrari]
		,isnull((select sum(e.valoare_amortizata-e.valoare_amortizata_cont_8045) from #fisamf e 
			where e.subunitate=rtrim(@sub) and e.felul_operatiei='5' 
			and data_lunii_operatiei between @datajos and @datasus and m.numar_de_inventar=e.numar_de_inventar
			and m.cont=e.cont_amortizare
			and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0) as [Valoare iesiri]
		,isnull((select sum(f.pret-(case when f.tip_miscare='MFF' then 0 else f.tva end))
			from mismf f 
			where f.subunitate=rtrim(@sub) and left(f.tip_miscare,1)='M' 
			 and f.data_lunii_de_miscare between @datajos and @datasus
			 and m.numar_de_inventar=f.numar_de_inventar 
			 and exists (select 1 from #fisamf g where g.subunitate=rtrim(@sub) 
						and g.felul_operatiei='4' and g.numar_de_inventar=f.numar_de_inventar 
						and data_lunii_operatiei between @datajos and @datasus 
						and m.cont=g.cont_amortizare
						and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%'))),0) 
			as [Valoare modificari]
		,'conturi de amortizare' as tip_cont
	FROM (select distinct numar_de_inventar, cont_amortizare as cont from #fisamf where subunitate=rtrim(@sub) and felul_operatiei='1' and left(cont_amortizare,1)<>'8') m
	--FROM #conturi_amortizare m where left(m.cont,1)<>'8'
	/*mfix m where m.subunitate='DENS' and 
		left(isnull((select top 1 convert(varchar(20),gestiune_primitoare) from mismf mm 
				where mm.subunitate=@sub and tip_miscare in ('MMF','MTO') and 
					data_lunii_de_miscare>=@datajos and mm.numar_de_inventar=m.numar_de_inventar 
				order by data_miscarii),cod_de_clasificare),1)<>'8'*/
UNION ALL
	SELECT @contcls8 as Cont,
		(select b.denumire_cont from conturi b where b.cont=@contcls8 
			and b.subunitate=rtrim(@sub)) as [Denumire cont]
		,isnull((select sum(c.valoare_amortizata_cont_8045) from #fisamf c where 
			c.subunitate=rtrim(@sub) and c.felul_operatiei='1' 
			and m.numar_de_inventar=c.numar_de_inventar 
			and data_lunii_operatiei=dateadd(d,-1,@datajos)
			and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0) as [Valoare inceput perioada]
	,isnull((select sum(d.amortizare_lunara_cont_8045) from #fisamf d where 
		d.subunitate=rtrim(@sub) and d.felul_operatiei='1' and data_lunii_operatiei between 
		@datajos and @datasus and m.numar_de_inventar=d.numar_de_inventar 
		and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0)
	  +isnull((select sum(h.Valoare_amortizata_cont_8045) from #fisamf h where h.subunitate=rtrim(@sub) 
		and h.felul_operatiei='3' and data_lunii_operatiei between @datajos and @datasus 
		and m.numar_de_inventar= h.numar_de_inventar
		and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0) as [Valoare intrari]
	,isnull((select sum(e.valoare_amortizata_cont_8045) from #fisamf e where 
		e.subunitate=rtrim(@sub) and e.felul_operatiei='5' and data_lunii_operatiei between 
		@datajos and @datasus and m.numar_de_inventar=e.numar_de_inventar
		and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')),0) as [Valoare iesiri]
	,isnull((select sum(f.tva) from mismf f where f.subunitate=rtrim(@sub) 
		and left(f.tip_miscare,1)='M' and f.tip_miscare<>'MFF' and f.data_lunii_de_miscare between 
		@datajos and @datasus  and m.numar_de_inventar=f.numar_de_inventar and exists (select 1 
		from #fisamf g where g.subunitate=rtrim(@sub) and g.felul_operatiei='4' 
		and g.numar_de_inventar=f.numar_de_inventar and data_lunii_operatiei between @datajos 
		and @datasus and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%'))),0) 
		as [Valoare modificari],
	'conturi de amortizare' as tip_cont
	FROM mfix m where m.subunitate=rtrim(@sub)
UNION ALL
	SELECT e.Cont_mijloc_fix,b.Denumire_cont,0,0,0,isnull(e.Valoare_de_inventar,0),'conturi mijloace fixe'
	FROM mismf m
		LEFT OUTER JOIN #fisamf e on e.subunitate=@sub and e.Felul_operatiei='4' 
			and e.Data_lunii_operatiei=m.Data_lunii_de_miscare and m.numar_de_inventar=e.numar_de_inventar 
			and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')
		LEFT OUTER JOIN conturi b on b.subunitate=@sub and cont=cont_mijloc_fix
	WHERE m.subunitate=@sub and (m.Tip_miscare='MMF' or m.Tip_miscare='MTP' and m.Cont_corespondent<>'') 
		and m.Data_miscarii between @datajos and @datasus
UNION ALL
	SELECT m.Cont_corespondent,b.Denumire_cont,0,0,0,-isnull(e.Valoare_de_inventar,0),'conturi mijloace fixe'
	FROM mismf m
		LEFT OUTER JOIN #fisamf e on e.subunitate=@sub and felul_operatiei='4'
			and data_lunii_operatiei=data_lunii_de_miscare and m.numar_de_inventar=e.numar_de_inventar
			and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%') 
		LEFT OUTER JOIN conturi b on b.subunitate=@sub and cont=cont_corespondent
	WHERE m.subunitate=@sub and (m.tip_miscare in ('MMF','MTO') or m.Tip_miscare='MTP' and m.Cont_corespondent<>'') 
		and data_miscarii between @datajos and @datasus
UNION ALL
	SELECT m.Subunitate_primitoare,b.Denumire_cont,0,0,0,
		isnull(e.Valoare_amortizata-e.Valoare_amortizata_cont_8045-(e.Amortizare_lunara-e.Amortizare_lunara_cont_8045),0),'conturi de amortizare'
	FROM mismf m
		LEFT OUTER JOIN #fisamf e on e.subunitate=@sub and felul_operatiei='4' 
			and data_lunii_operatiei=data_lunii_de_miscare and m.numar_de_inventar=e.numar_de_inventar
			and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')
		LEFT OUTER JOIN conturi b on b.subunitate=@sub and cont=subunitate_primitoare
	WHERE m.subunitate=@sub and (tip_miscare='MMF' or tip_miscare='MTP' and m.Gestiune_primitoare<>'' and m.Gestiune_primitoare<>m.Subunitate_primitoare) 
		and data_miscarii between @datajos and @datasus
UNION ALL
	SELECT m.Gestiune_primitoare,b.Denumire_cont,0,0,0,
		-isnull(e.Valoare_amortizata-e.Valoare_amortizata_cont_8045-(e.Amortizare_lunara-e.Amortizare_lunara_cont_8045),0),'conturi de amortizare'
	FROM mismf m
		LEFT OUTER JOIN #fisamf e on e.subunitate=@sub and felul_operatiei='4'
			and data_lunii_operatiei=data_lunii_de_miscare and m.numar_de_inventar=e.numar_de_inventar
			and (isnull(@lm,'')='' or loc_de_munca like rtrim(@lm)+'%')
		LEFT OUTER JOIN conturi b on b.subunitate=@sub and cont=gestiune_primitoare
	WHERE m.subunitate=@sub and (m.Tip_miscare in ('MMF','MTO') or m.tip_miscare='MTP' and m.Gestiune_primitoare<>'' and m.Gestiune_primitoare<>m.Subunitate_primitoare) 
		and m.Data_miscarii between @datajos and @datasus
-->	date pentru transferurile intre subunitati:

union all	--> valoare de inventar:
	select f.cont as cont, c.denumire_cont as denumire_cont,
			0 [Valoare inceput perioada],
			(case when (isnull(@lm,'')='' and @eLmUtiliz=0 and 1=0 or isnull(@lm,'')<>'' and lm_primitor like rtrim(@lm)+'%' --	daca fara loc de munca (filtre/proprietati) nu trebuie creat rulaj
				or @eLmUtiliz>0 and exists(select 1 from @LmUtiliz u where u.valoare=lm_primitor)) then f.Valoare_de_inventar else 0 end) [Valoare intrari], 
			(case when (isnull(@lm,'')='' and @eLmUtiliz=0 and 1=0 or isnull(@lm,'')<>'' and lm_predator like rtrim(@lm)+'%' --	daca fara loc de munca (filtre/proprietati) nu trebuie creat rulaj
				or @eLmUtiliz>0 and exists(select 1 from @LmUtiliz u where u.valoare=lm_predator)) then f.Valoare_de_inventar else 0 end) [Valoare iesiri],
			0 [Valoare modificari],
			'conturi mijloace fixe'--,f.*
		FROM #coresp_transferuri f
			left join conturi c on c.cont=f.Cont
union all	--> valoare amortizata:
	select f.cont_amortizare as cont, c.denumire_cont as denumire_cont,
			0 [Valoare inceput perioada],
			[Valoare intrari], 
			[Valoare iesiri], 0 [Valoare modificari],
			'conturi de amortizare'--,f.*
		FROM #amortizari_transferuri f
			left join conturi c on c.cont=f.Cont_amortizare and left(f.cont_amortizare,1) not like '8'
union all	--> valoare amortizata 8045:
	select @contcls8 as cont, c.denumire_cont as denumire_cont,
			0 [Valoare inceput perioada],
			f.[Valoare intrari 8045], 
			f.[Valoare iesiri 8045], 0 [Valoare modificari],
			'conturi de amortizare'--,f.*
		FROM #amortizari_transferuri f
			left join conturi c on c.cont=@contcls8
		where (f.[Valoare intrari 8045]<>0 or f.[valoare iesiri 8045]<>0) and left(f.cont_amortizare,1) not like '8'
/*union all
	select @contcls8 as cont, c.denumire_cont as denumire_cont,
			0 [Valoare inceput perioada],
			[Valoare intrari], 
			[Valoare iesiri], 0 [Valoare modificari],
			'conturi de amortizare'--,f.*
		FROM mfix m inner join #amortizari_transferuri f on m.numar_de_inventar=f.numar_de_inventar
			left join conturi c on c.cont=f.Cont_amortizare 
			where m.subunitate=rtrim(@sub)*/
)z 
where ([Valoare inceput perioada]<>0 or [Valoare intrari]<>0 or [Valoare iesiri]<>0 
	or [Valoare modificari]<>0 or (isnull([Valoare inceput perioada],0)+
	isnull([Valoare intrari],0)-isnull([Valoare iesiri],0)+isnull([Valoare modificari],0))<>0 
	or (isnull([Valoare intrari],0)-isnull([Valoare iesiri],0)+
	isnull([Valoare modificari],0))<>0) and (@cont is null or cont like rtrim(@cont)+'%')
group by cont,tip_cont
order by tip_cont desc,cont--*/

if object_id('tempdb.dbo.#dens') is not null drop table #dens
if object_id('tempdb.dbo.#fisamf') is not null drop table #fisamf
if object_id('tempdb.dbo.#coresp_transferuri') is not null drop table #coresp_transferuri
if object_id('tempdb.dbo.#amortizari_transferuri') is not null drop table #amortizari_transferuri
if object_id('tempdb.dbo.#conturi_amortizare') is not null drop table #conturi_amortizare
