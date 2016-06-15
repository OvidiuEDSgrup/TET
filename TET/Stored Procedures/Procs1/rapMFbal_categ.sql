--***
create procedure rapMFbal_categ @datajos datetime, @datasus datetime, 
	@tipimob int=null,		--> filtru tip imobilizare: [null,1]=MF, 2=obiecte de inventar, 3= MF dupa casare
	@lista int=null,		--> filtru tip: [null,1]=toate, 2=MF propriu-zise, 3= MF de natura ob inv
	@categorie varchar(50)=null,		--> filtru categorie
	@cont varchar(50)=null,				--> filtru cont; (se presupune ca e de imobilizare)
	@tippatrimoniu varchar(50)=null,	--> filtru tip patrimoniu; [null, 3]=toate, 0=Privat, 1=Public, 2=Altele
	@tipamortizare int=null,			--> filtru tip amortizare; [null, 3]=toate, 1=amortizat, 2=in curs de amortizare
	@locm varchar(50)=null,				--> filtru loc de munca, cu like
	@nr_inventar varchar(50)=null
/*
Ex. apelare:
declare @datajos datetime='2014-03-01', @datasus datetime='2014-03-31', 
	@tipimob int=null,		--> filtru tip imobilizare: [null,1]=MF, 2=obiecte de inventar, 3= MF dupa casare
	@lista int=null,		--> filtru tip: [null,1]=toate, 2=MF propriu-zise, 3= MF de natura ob inv
	@categorie varchar(50)=null,		--> filtru categorie
	@cont varchar(50)=null,				--> filtru cont; (se presupune ca e de imobilizare)
	@tippatrimoniu varchar(50)=null,	--> filtru tip patrimoniu; [null, 3]=toate, 0=Privat, 1=Public, 2=Altele
	@tipamortizare int=null,			--> filtru tip amortizare; [null, 3]=toate, 1=amortizat, 2=in curs de amortizare
	@locm varchar(50)=null,				--> filtru loc de munca, cu like
	@nr_inventar varchar(50)=null

exec rapMFbal_categ @datajos, @datasus, @tipimob,@lista,@categorie, @cont, @tippatrimoniu, @tipamortizare, @locm, @nr_inventar

*/
as 
set transaction isolation level read uncommitted 
declare @sub char(9) 
set @sub = isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'),'')

if object_id('tempdb.dbo.#patrimonii') is not null drop table #patrimonii --> prefiltrare pt #fisamf
if object_id('tempdb.dbo.#fisamf') is not null drop table #fisamf	--> prefiltrare pt #val_inventar
if object_id('tempdb.dbo.#val_inventar') is not null drop table #val_inventar	--> baza pt valorile de inventar si #val_amortizare
if object_id('tempdb.dbo.#mf_categ') is not null drop table #mf_categ	--> valorile de inventar pe categorii
if object_id('tempdb.dbo.#mfa_categ') is not null drop table #mfa_categ	--> amortizarile pe categorii
if object_id('tempdb.dbo.#coresp_transferuri') is not null drop table #coresp_transferuri	--> calcul valori de inventar din TSE
if object_id('tempdb.dbo.#amortizari_transferuri') is not null drop table #amortizari_transferuri	-->	calcul amortizari din TSE

--< Filtrare pe locuri de munca pe utilizatori
	declare @utilizator varchar(20), @eLmUtiliz int
	select @utilizator=dbo.fIaUtilizator('')
	declare @LmUtiliz table(valoare varchar(200))
	set @eLmUtiliz=0
	insert into @LmUtiliz(valoare)
	select cod from lmfiltrare where utilizator=@utilizator
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
--/>

select	@tipimob=isnull(@tipimob,1), @lista=isnull(@lista,'1'),
		@categorie=@categorie+'%',--isnull(@categorie,''), 
		@cont=@cont+'%',
		@tippatrimoniu=isnull(case @tippatrimoniu when '0' then ''
											when '2' then '0'
											else @tippatrimoniu
											end,'3'),
		@tipamortizare=isnull(@tipamortizare,3),
		@locm=@locm+'%'
	--<	prefiltrari
		--< sectiune de filtrare pe patrimoniu
	select mf.tert as tip_patrimoniu, mf.Numar_de_inventar
		into #patrimonii
				from mismf mf where mf.tip_miscare='mtp' --order by mf.Data_lunii_de_miscare desc
				and not exists (select 1 from mismf mf1 where mf1.tip_miscare='mtp' and mf1.Numar_de_inventar=mf.Numar_de_inventar 
								and (mf1.Data_lunii_de_miscare>mf.Data_lunii_de_miscare or 
									mf1.Data_lunii_de_miscare=mf.Data_lunii_de_miscare and mf1.Numar_document>mf.Numar_document))
								
	create /*unique */index indx_patrimonii on #patrimonii(numar_de_inventar)
	insert into #patrimonii(tip_patrimoniu, Numar_de_inventar)
		select p.Tip_amortizare, p.Numar_de_inventar from mfix p where p.subunitate='DENS'
		and not exists(select 1 from #patrimonii m where m.Numar_de_inventar=p.Numar_de_inventar)		

	-- /sectiune de filtrare pe patrimoniu
	select f.Subunitate, f.Numar_de_inventar, f.Categoria, f.Data_lunii_operatiei, f.Felul_operatiei, 
		f.Loc_de_munca, f.Gestiune, f.Comanda, f.Valoare_de_inventar, f.Valoare_amortizata, 
		f.Valoare_amortizata_cont_8045, f.Valoare_amortizata_cont_6871, f.Amortizare_lunara, 
		f.Amortizare_lunara_cont_8045, f.Amortizare_lunara_cont_6871, f.Durata, f.Obiect_de_inventar, 
		f.Cont_mijloc_fix, f.Numar_de_luni_pana_la_am_int, f.Cantitate
		into #fisamf
		from fisamf f 
		left join #patrimonii p on p.Numar_de_inventar=f.Numar_de_inventar
		where	(@categorie is null or f.categoria like @categorie)
				and (@cont is null or f.cont_mijloc_fix like @cont)
				and (@tippatrimoniu='3' or p.tip_patrimoniu is not null and p.tip_patrimoniu=@tippatrimoniu)
				and (@tipamortizare=3 or @tipamortizare=1 and f.Valoare_de_inventar<=f.Valoare_amortizata or @tipamortizare=2 and f.Valoare_de_inventar>f.Valoare_amortizata)
				and (@eLmUtiliz=0 or exists(select 1 from @LmUtiliz u where u.valoare=f.Loc_de_munca))
				and (@locm is null or f.Loc_de_munca like @locm)
				and (@nr_inventar is null or f.numar_de_inventar like @nr_inventar)
	CREATE /*UNIQUE */CLUSTERED INDEX Subunitate_Nrinv_Perioada ON #fisaMF
		(
			Subunitate ASC,
			Numar_de_inventar ASC,
			Data_lunii_operatiei ASC,
			Felul_operatiei ASC
		)
	-->	tabela de baza pt valori de inventar si valori amortizate
	select f.valoare_de_inventar, f.felul_operatiei, f.data_lunii_operatiei, f.numar_de_inventar,
			f.categoria, f.valoare_amortizata, f.amortizare_lunara
	into #val_inventar
	from #fisamf f 
	left outer join mfix m on m.subunitate='DENS' and f.numar_de_inventar = m.numar_de_inventar 
	where --felul_operatiei='5' and 
		data_lunii_operatiei between dateadd(day,-1,@datajos) and @datasus
		and ltrim(rtrim(f.subunitate))=rtrim(ltrim(@sub)) --and m.subunitate = 'DENS' 
		and (case when (@tipimob = 1 and @lista = 1 and isnull(m.serie,'') = '') then 1 --MF toate 
			when (@tipimob = 1 and @lista = 2 and f.obiect_de_inventar=0 and isnull(m.serie,'') = '') then 1 --MF propriu-zise 
			when (@tipimob = 1 and @lista = 3 and f.obiect_de_inventar=1 and isnull(m.serie,'') = '') then 1 --MF de nat. ob. inv. 
			when (@tipimob = 2 and @lista = 1 and isnull(m.serie,'') = 'O') then 1 --OB. inv. - lista 
			--when (@tipimob = 3 and @lista = 1 and c.serie = 'C') then 1 --MF dupa casare -lista 
			else 0 end )=1 
	--> corespondente subunitati (lm) pe documente tip transfer (TSE)
	select m.data_lunii_de_miscare, m.numar_de_inventar
		,max(f1.loc_de_munca) lm_predator
		,max(f.loc_de_munca) lm_primitor
		,max(f.valoare_de_inventar) valoare_de_inventar
		,max(f.cont_mijloc_fix) cont
		,isnull(max(f.Cont_amortizare),isnull((select top 1 convert(varchar(40),gestiune_primitoare) 
				from mismf mm 
				where mm.subunitate=@sub and tip_miscare in ('MMF','MTO') and data_lunii_de_miscare>=@datajos and mm.numar_de_inventar=m.numar_de_inventar 
				order by data_miscarii),'')) as cont_amortizare
		,max(f.categoria) categoria
	into #coresp_transferuri
	FROM mismf m
		inner join fisamf f on f.subunitate=m.Subunitate and f.felul_operatiei='1' and f.data_lunii_operatiei=m.data_lunii_de_miscare and m.numar_de_inventar=f.numar_de_inventar
		left join #patrimonii p on p.Numar_de_inventar=m.Numar_de_inventar
		inner join fisamf f1 on f1.subunitate=m.Subunitate and m.numar_de_inventar=f1.numar_de_inventar and f1.Data_lunii_operatiei<=f.Data_lunii_operatiei and f1.loc_de_munca<>f.loc_de_munca
			and	not exists (select 1 from fisamf f2 where f2.subunitate=m.Subunitate and f1.numar_de_inventar=f2.numar_de_inventar and f2.Data_lunii_operatiei<f.data_lunii_operatiei and f2.Data_lunii_operatiei>f1.data_lunii_operatiei)
		--left join fisamf ft on ft.subunitate=m.Subunitate and ft.felul_operatiei='6' and ft.data_lunii_operatiei=m.data_lunii_de_miscare and m.numar_de_inventar=ft.numar_de_inventar
		left join mfix mf on mf.numar_de_inventar=m.numar_de_inventar and mf.subunitate='DENS'
	where m.subunitate=@sub and m.Data_lunii_de_miscare between @datajos and @datasus and left(m.Tip_miscare,1)='T' 
		and m.Cont_corespondent<>'' 
		and (@eLmUtiliz=0 or exists(select 1 from @LmUtiliz u where u.valoare=f.Loc_de_munca or u.valoare=f1.loc_de_munca))
		and (@nr_inventar is null or f.numar_de_inventar = @nr_inventar)
		and (isnull(@locm,'')='' or f1.loc_de_munca like @locm+'%' or f.loc_de_munca like @locm+'%' /*or ft.loc_de_munca like @locm+'%'*/)
		and ltrim(rtrim(f.subunitate))=rtrim(ltrim(@sub)) --and mf.subunitate = 'DENS' 
		and (case when (@tipimob = 1 and @lista = 1 and isnull(mf.serie,'') = '') then 1 --MF toate 
			when (@tipimob = 1 and @lista = 2 and f.obiect_de_inventar=0 and isnull(mf.serie,'') = '') then 1 --MF propriu-zise 
			when (@tipimob = 1 and @lista = 3 and f.obiect_de_inventar=1 and isnull(mf.serie,'') = '') then 1 --MF de nat. ob. inv. 
			when (@tipimob = 2 and @lista = 1 and isnull(mf.serie,'') = 'O') then 1
			else 0 end)=1
		and (@categorie is null or f.categoria like @categorie)
		and (@cont is null or f.cont_mijloc_fix like @cont)
		and (@tippatrimoniu='3' or p.tip_patrimoniu is not null and p.tip_patrimoniu=@tippatrimoniu)
		and (@tipamortizare=3 or @tipamortizare=1 and f.Valoare_de_inventar<=f.Valoare_amortizata 
						or @tipamortizare=2 and f.Valoare_de_inventar>f.Valoare_amortizata)
	group by m.data_lunii_de_miscare, m.numar_de_inventar
	--> modificari amortizari rezultate din transferuri (TSE)
	select	m.categoria, m.numar_de_inventar, 
			sum(case when felul_operatiei='1' --	intrare=valoare amortizata din luna precedenta. Amortizarea lunare se inregistreaza pe lm primitor
					then d.valoare_amortizata-d.Valoare_amortizata_cont_8045-(d.amortizare_lunara-d.amortizare_lunara_cont_8045) /*d.amortizare_lunara-d.amortizare_lunara_cont_8045*/
				when felul_operatiei='3' /*or felul_operatiei='6'*/ /*and @locm<>''*/ then d.valoare_amortizata-d.Valoare_amortizata_cont_8045 
				else 0 end)
			as [valoare intrari]
			,sum(case when felul_operatiei='5' then d.valoare_amortizata-d.valoare_amortizata_cont_8045
					else 0 end)
			as [valoare iesiri]
			,max(lm_primitor) lm--, m.cont_amortizare
	into #amortizari_transferuri
	FROM #coresp_transferuri m 
	inner join fisamf d on m.numar_de_inventar=d.numar_de_inventar and lm_primitor=d.loc_de_munca and m.Data_lunii_de_miscare=d.Data_lunii_operatiei
		where d.subunitate=rtrim(@sub) and d.data_lunii_operatiei between @datajos and @datasus 
			and (isnull(@locm,'')='' and 1=0 or lm_primitor like rtrim(@locm)+'%')
			--and (isnull(@locm,'')='' or m.lm_predator like @locm+'%')
		group by m.numar_de_inventar--, m.cont_amortizare
			,m.categoria
	union all
	select	m.categoria, m.numar_de_inventar, 
			sum(case when felul_operatiei='5' then d.valoare_amortizata-d.valoare_amortizata_cont_8045
					else 0 end) 
			as [valoare intrari]
			,sum(case when felul_operatiei='1' --	iesire=valoare amortizata din luna precedenta. Amortizarea lunare se inregistreaza pe lm primitor.
					then d.valoare_amortizata-d.Valoare_amortizata_cont_8045-(d.amortizare_lunara-d.amortizare_lunara_cont_8045) /*d.amortizare_lunara-d.amortizare_lunara_cont_8045*/ 
				when felul_operatiei='3' then d.valoare_amortizata-d.Valoare_amortizata_cont_8045 
				else 0 end)
			as [valoare iesiri]
			,max(lm_predator) lm--, m.cont_amortizare
	FROM #coresp_transferuri m 
	inner join fisamf d on m.numar_de_inventar=d.numar_de_inventar and lm_primitor=d.loc_de_munca and m.Data_lunii_de_miscare=d.Data_lunii_operatiei
		where d.subunitate=rtrim(@sub) and d.data_lunii_operatiei between @datajos and @datasus 
			and (isnull(@locm,'')='' and 1=0 or lm_predator like rtrim(@locm)+'%')
			--and (isnull(@locm,'')='' or m.lm_primitor like @locm+'%')
	group by m.numar_de_inventar--, m.cont_amortizare
			,m.categoria

	-- select * from #coresp_transferuri
	-- select * from #amortizari_transferuri
	-- /prefiltrari>
	
	--> sectiune valori de inventar:
select * into #mf_categ from ( 
select 'Valoare de inventar la '+convert(varchar ,@datajos,103) as Explicatii, 
	isnull(round(sum(case when categoria='1' then valoare_de_inventar else 0 end),2),0) as c1, 
	isnull(round(sum(case when categoria='21' then valoare_de_inventar else 0 end),2),0) as c21, 
	isnull(round(sum(case when categoria='22' then valoare_de_inventar else 0 end),2),0) as c22, 
	isnull(round(sum(case when categoria='23' then valoare_de_inventar else 0 end),2),0) as c23, 
	isnull(round(sum(case when categoria='24' then valoare_de_inventar else 0 end),2),0) as c24, 
	isnull(round(sum(case when categoria='3' then valoare_de_inventar else 0 end),2),0) as c3, 
	isnull(round(sum(case when categoria='7' then valoare_de_inventar else 0 end),2),0) as c7, 
	isnull(round(sum(case when categoria='8' then valoare_de_inventar else 0 end),2),0) as c8, 
	isnull(round(sum(case when categoria='9' then valoare_de_inventar else 0 end),2),0) as c9, 
	1 as nr 
from #val_inventar
where rtrim(felul_operatiei)='1' and data_lunii_operatiei=dateadd(day,-1,@datajos)
--><		"--><" = semnalizator de sfarsit de "where"
union all 
select 'Intrari in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii, 
	isnull(round(sum(case when categoria='1' then valoare_de_inventar else 0 end),2),0) as c1, 
	isnull(round(sum(case when categoria='21' then valoare_de_inventar else 0 end),2),0) as c21, 
	isnull(round(sum(case when categoria='22' then valoare_de_inventar else 0 end),2),0) as c22, 
	isnull(round(sum(case when categoria='23' then valoare_de_inventar else 0 end),2),0) as c23, 
	isnull(round(sum(case when categoria='24' then valoare_de_inventar else 0 end),2),0) as c24, 
	isnull(round(sum(case when categoria='3' then valoare_de_inventar else 0 end),2),0) as c3, 
	isnull(round(sum(case when categoria='7' then valoare_de_inventar else 0 end),2),0) as c7, 
	isnull(round(sum(case when categoria='8' then valoare_de_inventar else 0 end),2),0) as c8, 
	isnull(round(sum(case when categoria='9' then valoare_de_inventar else 0 end),2),0) as c9, 
	2 as nr 
from #val_inventar
where felul_operatiei='3' and data_lunii_operatiei between @datajos and @datasus 
--><
union all 
select 'Iesiri in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii, 
	isnull(round(sum(case when categoria='1' then valoare_de_inventar else 0 end),2),0) as c1, 
	isnull(round(sum(case when categoria='21' then valoare_de_inventar else 0 end),2),0) as c21, 
	isnull(round(sum(case when categoria='22' then valoare_de_inventar else 0 end),2),0) as c22, 
	isnull(round(sum(case when categoria='23' then valoare_de_inventar else 0 end),2),0) as c23, 
	isnull(round(sum(case when categoria='24' then valoare_de_inventar else 0 end),2),0) as c24, 
	isnull(round(sum(case when categoria='3' then valoare_de_inventar else 0 end),2),0) as c3, 
	isnull(round(sum(case when categoria='7' then valoare_de_inventar else 0 end),2),0) as c7, 
	isnull(round(sum(case when categoria='8' then valoare_de_inventar else 0 end),2),0) as c8, 
	isnull(round(sum(case when categoria='9' then valoare_de_inventar else 0 end),2),0) as c9, 
	3 as nr 
from #val_inventar
where felul_operatiei='5' and data_lunii_operatiei between @datajos and @datasus
--><
union all 
select 'Modificari in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii,
	(select isnull(round(sum(f.diferenta_de_valoare),2),0) 
	from #val_inventar g
		inner join mismf f on g.numar_de_inventar=f.numar_de_inventar 
							and f.data_lunii_de_miscare=g.data_lunii_operatiei
	where f.subunitate=rtrim(@sub) and left(f.tip_miscare,1)='M' and g.categoria='1'
		and g.felul_operatiei='4' and g.data_lunii_operatiei between @datajos and @datasus
	--><
	) as c1, 
	/* am skipat partea asta de 21, am facut 21 dupa model 22:
	(select isnull(round(sum(f.diferenta_de_valoare),2),0) --> 'C21' are regim special, se pare:
	from mismf f inner  join
		/**--> subselect-ul urmator ia toate asocierile numar_de_inventar, cont_mijloc_fix, categoria;
				asa trebuie sau poate fi scris mai frumos?
		*/
		(select distinct f.numar_de_inventar, cont_mijloc_fix,categoria from #fisamf f 
		left outer join mfix m on m.subunitate = 'DENS' and f.numar_de_inventar = m.numar_de_inventar 
		where f.subunitate=rtrim(@sub) and felul_operatiei='1' 
		--and m.subunitate = 'DENS' 
		and (case when (@tipimob = 1 and @lista = 1 and isnull(m.serie,'') = '') then 1 --MF toate 
		 when (@tipimob = 1 and @lista = 2 and f.obiect_de_inventar=0 and isnull(m.serie,'') = '') then 1 --MF propriu-zise 
		 when (@tipimob = 1 and @lista = 3 and f.obiect_de_inventar=1 and isnull(m.serie,'') = '') then 1 --MF de nat. ob. inv. 
		 when (@tipimob = 2 and @lista = 1 and isnull(m.serie,'') = 'O') then 1 --OB. inv. - lista 
		 --when (@tipimob = 3 and @lista = 1 and c.serie = 'C') then 1 --MF dupa casare -lista 
		else 0 end )=1
		--><
		) g on g.numar_de_inventar=f.numar_de_inventar
	--#fisamf g 
	where f.subunitate=rtrim(@sub) and left(f.tip_miscare,1)='M' and g.categoria='21' 
		and f.data_lunii_de_miscare between @datajos and @datasus --and g.subunitate=rtrim(@sub) 
		--and g.felul_operatiei='4' 
		and exists (select 1 from #fisamf a where 
				(case when (@tipimob = 1 and @lista = 1) then 1 --MF toate 
				 when (@tipimob = 1 and @lista = 2 and a.obiect_de_inventar=0) then 1 --MF propriu-zise 
				 when (@tipimob = 1 and @lista = 3 and a.obiect_de_inventar=1) then 1 --MF de nat. ob. inv. 
				 when (@tipimob = 2 and @lista = 1) then 1 --OB. inv. - lista 
			 --when (@tipimob = 3 and @lista = 1 and c.serie = 'C') then 1 --MF dupa casare -lista 
				else 0 end )=1
				and a.subunitate=rtrim(@sub) and a.felul_operatiei='4' and a.numar_de_inventar=g.numar_de_inventar 
				and g.cont_mijloc_fix=a.cont_mijloc_fix and data_lunii_operatiei between @datajos and @datasus
			 --><
			 ) ) as c21, */
	(select isnull(round(sum(f.diferenta_de_valoare),2),0) 
	from #val_inventar g 
		inner join mismf f on g.numar_de_inventar=f.numar_de_inventar and f.data_lunii_de_miscare=g.data_lunii_operatiei
	where f.subunitate=rtrim(@sub) and left(f.tip_miscare,1)='M' and g.categoria='21'
		and g.felul_operatiei='4' and g.Data_lunii_operatiei between @datajos and @datasus
	--><
	) as c21, 
	(select isnull(round(sum(f.diferenta_de_valoare),2),0) 
	from #val_inventar g 
		inner join mismf f on g.numar_de_inventar=f.numar_de_inventar and f.data_lunii_de_miscare=g.data_lunii_operatiei
	where f.subunitate=rtrim(@sub) and left(f.tip_miscare,1)='M' and g.categoria='22'
		and g.felul_operatiei='4' and g.Data_lunii_operatiei between @datajos and @datasus
	--><
	) as c22, 
	(select isnull(round(sum(f.diferenta_de_valoare),2),0) 
		from #val_inventar g
			inner join mismf f on f.numar_de_inventar = g.numar_de_inventar
					-->? nu trebuie ca mai sus, adica inclus in conditia de join "and f.data_lunii_de_miscare=g.data_lunii_operatiei"?
	where  /*and g.obiect_de_inventar = 0 and */ f.subunitate=rtrim(@sub) and left(f.tip_miscare,1)='M'
		and data_lunii_operatiei between @datajos and @datasus and g.categoria='23'
		and f.data_lunii_de_miscare between @datajos and @datasus 
		and g.felul_operatiei='4'
	--><
	) as c23, 
	(select isnull(round(sum(f.diferenta_de_valoare),2),0) 
	from #val_inventar g
		 inner join mismf f on g.numar_de_inventar=f.numar_de_inventar
	where /*and g.obiect_de_inventar = 0 and*/ 
		f.subunitate=rtrim(@sub) and left(f.tip_miscare,1)='M' and 
		f.data_lunii_de_miscare between @datajos and @datasus and g.felul_operatiei='4'
		and data_lunii_operatiei between @datajos and @datasus and g.categoria='24'
	--><
	) as c24, 
	(select isnull(round(sum(f.diferenta_de_valoare),2),0) 
	from #val_inventar g
		inner join mismf f on g.numar_de_inventar=f.numar_de_inventar
	where /*and g.obiect_de_inventar = 0 and*/ f.subunitate=rtrim(@sub)
		and left(f.tip_miscare,1)='M' and f.data_lunii_de_miscare between @datajos and @datasus
		and g.felul_operatiei='4'
		and data_lunii_operatiei between @datajos and @datasus and g.categoria='3'
	--><
	) as c3, 
	(select isnull(round(sum(f.diferenta_de_valoare),2),0) 
	from #val_inventar g
		inner join mismf f on g.numar_de_inventar=f.numar_de_inventar
	where /*and g.obiect_de_inventar = 0 and*/ f.subunitate=rtrim(@sub) and left(f.tip_miscare,1)='M' and 
		f.data_lunii_de_miscare between @datajos and @datasus and g.felul_operatiei='4' and f.data_lunii_de_miscare=g.data_lunii_operatiei
		and data_lunii_operatiei between @datajos and @datasus and g.categoria='7'
	--><
	) as c7, 
	(select isnull(round(sum(f.diferenta_de_valoare),2),0) 
	from #val_inventar g
		inner join mismf f on g.numar_de_inventar=f.numar_de_inventar
	where /*and g.obiect_de_inventar = 0 and*/ f.subunitate=rtrim(@sub) 
		and left(f.tip_miscare,1)='M' and f.data_lunii_de_miscare between @datajos and @datasus
		and g.felul_operatiei='4' and data_lunii_operatiei between @datajos and @datasus 
		and g.categoria='8'
	--><
	) as c8, 
	(select isnull(round(sum(f.diferenta_de_valoare),2),0) 
	from #val_inventar g
		inner join mismf f on g.numar_de_inventar=f.numar_de_inventar
	where /*and g.obiect_de_inventar = 0 and*/ f.subunitate=rtrim(@sub) and left(f.tip_miscare,1)='M'
		and f.data_lunii_de_miscare between @datajos and @datasus and g.felul_operatiei='4'
		and data_lunii_operatiei between @datajos and @datasus and g.categoria='9'
	--><
	) as c9 , 
	4 as nr
) as t 
	 /*--test<  select * from #mf_categ
	 select 'Valoare de inventar la '+convert(varchar ,@datajos,103) as Explicatii, 
	isnull(round(sum(case when categoria='1' then valoare_de_inventar else 0 end),2),0) as c1, 
	isnull(round(sum(case when categoria='21' then valoare_de_inventar else 0 end),2),0) as c21, 
	isnull(round(sum(case when categoria='22' then valoare_de_inventar else 0 end),2),0) as c22, 
	isnull(round(sum(case when categoria='23' then valoare_de_inventar else 0 end),2),0) as c23, 
	isnull(round(sum(case when categoria='24' then valoare_de_inventar else 0 end),2),0) as c24, 
	isnull(round(sum(case when categoria='3' then valoare_de_inventar else 0 end),2),0) as c3, 
	isnull(round(sum(case when categoria='7' then valoare_de_inventar else 0 end),2),0) as c7, 
	isnull(round(sum(case when categoria='8' then valoare_de_inventar else 0 end),2),0) as c8, 
	isnull(round(sum(case when categoria='9' then valoare_de_inventar else 0 end),2),0) as c9, 
	1 as nr 
	from #fisamf f 
	inner join mfix m on f.numar_de_inventar = m.numar_de_inventar 
	where rtrim(felul_operatiei)='1' and data_lunii_operatiei=dateadd(day,-1,@datajos) and ltrim(rtrim(f.subunitate))=rtrim(ltrim(@sub)) 
	and m.subunitate = 'DENS' 
	and (case when (@tipimob = 1 and @lista = 1 /*and m.serie = ''*/) then 1 --MF toate 
	 when (@tipimob = 1 and @lista = 2 and f.obiect_de_inventar=0 /*and m.serie = ''*/) then 1 --MF propriu-zise 
	 when (@tipimob = 1 and @lista = 3 and f.obiect_de_inventar=1 /*and m.serie = ''*/) then 1 --MF de nat. ob. inv. 
	 when (@tipimob = 2 and @lista = 1 and m.serie = 'O') then 1 --OB. inv. - lista 
	 --when (@tipimob = 3 and @lista = 1 and c.serie = 'C') then 1 --MF dupa casare -lista 
	else 0 end )=1 
	 --/test>*/

	--> sectiune amortizari:
select * into #mfa_categ from ( 
	select 'Amortizare cumulata la '+convert(varchar ,@datajos,103) as Explicatii, 
		isnull(round(sum(case when categoria='1' then valoare_amortizata else 0 end),2),0) as c1, 
		isnull(round(sum(case when categoria='21' then valoare_amortizata else 0 end),2),0) as c21, 
		isnull(round(sum(case when categoria='22' then valoare_amortizata else 0 end),2),0) as c22, 
		isnull(round(sum(case when categoria='23' then valoare_amortizata else 0 end),2),0) as c23, 
		isnull(round(sum(case when categoria='24' then valoare_amortizata else 0 end),2),0) as c24, 
		isnull(round(sum(case when categoria='3' then valoare_amortizata else 0 end),2),0) as c3, 
		isnull(round(sum(case when categoria='7' then valoare_amortizata else 0 end),2),0) as c7, 
		isnull(round(sum(case when categoria='8' then valoare_amortizata else 0 end),2),0) as c8, 
		isnull(round(sum(case when categoria='9' then valoare_amortizata else 0 end),2),0) as c9, 
		1 as nr 
	from #val_inventar
	where data_lunii_operatiei=dateadd(day,-1,@datajos) and felul_operatiei='1'
	--><
	union all 
	select 'Amortizare calculata in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii, 
		isnull(round(sum(case when categoria='1' then amortizare_lunara else 0 end),2),0) as c1, 
		isnull(round(sum(case when categoria='21' then amortizare_lunara else 0 end),2),0) as c21, 
		isnull(round(sum(case when categoria='22' then amortizare_lunara else 0 end),2),0) as c22, 
		isnull(round(sum(case when categoria='23' then amortizare_lunara else 0 end),2),0) as c23, 
		isnull(round(sum(case when categoria='24' then amortizare_lunara else 0 end),2),0) as c24, 
		isnull(round(sum(case when categoria='3' then amortizare_lunara else 0 end),2),0) as c3, 
		isnull(round(sum(case when categoria='7' then amortizare_lunara else 0 end),2),0) as c7, 
		isnull(round(sum(case when categoria='8' then amortizare_lunara else 0 end),2),0) as c8, 
		isnull(round(sum(case when categoria='9' then amortizare_lunara else 0 end),2),0) as c9, 
		2 as nr 
	from #val_inventar
	where data_lunii_operatiei between @datajos and @datasus and felul_operatiei='1'
	--><
	union all 
	select 'Amortizare intrari in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii, 
		isnull(round(sum(case when categoria='1' then valoare_amortizata else 0 end),2),0) as c1, 
		isnull(round(sum(case when categoria='21' then valoare_amortizata else 0 end),2),0) as c21, 
		isnull(round(sum(case when categoria='22' then valoare_amortizata else 0 end),2),0) as c22, 
		isnull(round(sum(case when categoria='23' then valoare_amortizata else 0 end),2),0) as c23, 
		isnull(round(sum(case when categoria='24' then valoare_amortizata else 0 end),2),0) as c24, 
		isnull(round(sum(case when categoria='3' then valoare_amortizata else 0 end),2),0) as c3, 
		isnull(round(sum(case when categoria='7' then valoare_amortizata else 0 end),2),0) as c7, 
		isnull(round(sum(case when categoria='8' then valoare_amortizata else 0 end),2),0) as c8, 
		isnull(round(sum(case when categoria='9' then valoare_amortizata else 0 end),2),0) as c9, 
		3 as nr 
	from #val_inventar
	where data_lunii_operatiei between @datajos and @datasus and felul_operatiei='3' 
	--><
	union all 
	select 'Amortizare cedata la iesiri in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii, 
		isnull(round(sum(case when categoria='1' then valoare_amortizata else 0 end),2),0) as c1, 
		isnull(round(sum(case when categoria='21' then valoare_amortizata else 0 end),2),0) as c21, 
		isnull(round(sum(case when categoria='22' then valoare_amortizata else 0 end),2),0) as c22, 
		isnull(round(sum(case when categoria='23' then valoare_amortizata else 0 end),2),0) as c23, 
		isnull(round(sum(case when categoria='24' then valoare_amortizata else 0 end),2),0) as c24, 
		isnull(round(sum(case when categoria='3' then valoare_amortizata else 0 end),2),0) as c3, 
		isnull(round(sum(case when categoria='7' then valoare_amortizata else 0 end),2),0) as c7, 
		isnull(round(sum(case when categoria='8' then valoare_amortizata else 0 end),2),0) as c8, 
		isnull(round(sum(case when categoria='9' then valoare_amortizata else 0 end),2),0) as c9, 
		4 as nr 
	from #val_inventar
	where data_lunii_operatiei between @datajos and @datasus and felul_operatiei='5' 
	--><
	union all 
	select 'Modificari amortizare in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii, 
		isnull(round(sum(case when categoria='1' then f.pret else 0 end),2),0) as c1, 
		isnull(round(sum(case when categoria='21' then f.pret else 0 end),2),0) as c21, 
		isnull(round(sum(case when categoria='22' then f.pret else 0 end),2),0) as c22, 
		isnull(round(sum(case when categoria='23' then f.pret else 0 end),2),0) as c23, 
		isnull(round(sum(case when categoria='24' then f.pret else 0 end),2),0) as c24, 
		isnull(round(sum(case when categoria='3' then f.pret else 0 end),2),0) as c3, 
		isnull(round(sum(case when categoria='7' then f.pret else 0 end),2),0) as c7, 
		isnull(round(sum(case when categoria='8' then f.pret else 0 end),2),0) as c8, 
		isnull(round(sum(case when categoria='9' then f.pret else 0 end),2),0) as c9, 
		5 as nr 
	from #fisamf a
		inner join mfix m on a.numar_de_inventar = m.numar_de_inventar
		inner join mismf f on f.numar_de_inventar=a.numar_de_inventar
	where /*and a.obiect_de_inventar = 0 and*/
		left(f.tip_miscare,1)='M' and f.data_lunii_de_miscare between @datajos and @datasus 
		and f.subunitate='DENS'
		and ltrim(rtrim(a.subunitate))=rtrim(ltrim(@sub)) and m.subunitate = 'DENS' 
		and (case when (@tipimob = 1 and @lista = 1 /*and m.serie = ''*/) then 1 --MF toate 
			 when (@tipimob = 1 and @lista = 2 and a.obiect_de_inventar=0 /*and m.serie = ''*/) then 1 --MF propriu-zise 
			 when (@tipimob = 1 and @lista = 3 and a.obiect_de_inventar=1 /*and m.serie = ''*/) then 1 --MF de nat. ob. inv. 
			 when (@tipimob = 2 and @lista = 1 and m.serie = 'O') then 1 --OB. inv. - lista 
			 --when (@tipimob = 3 and @lista = 1 and c.serie = 'C') then 1 --MF dupa casare -lista 
			else 0 end )=1 
	--><
	 and exists (select 1 from #val_inventar g where g.felul_operatiei='4' 
				and data_lunii_operatiei between @datajos and @datasus
				and g.numar_de_inventar=f.numar_de_inventar
		--><
	)) as s 
	-->	completare date (intrari/iesiri) din transferurile intre subunitati (TSE):
insert into #mf_categ (explicatii, c1,c21,c22,c23, c24, c3,c7,c8,c9,nr)
			-->	intrari:
select 'Intrari in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii, 
	isnull(round(sum(case when categoria='1' then valoare_de_inventar else 0 end),2),0) as c1, 
	isnull(round(sum(case when categoria='21' then valoare_de_inventar else 0 end),2),0) as c21, 
	isnull(round(sum(case when categoria='22' then valoare_de_inventar else 0 end),2),0) as c22, 
	isnull(round(sum(case when categoria='23' then valoare_de_inventar else 0 end),2),0) as c23, 
	isnull(round(sum(case when categoria='24' then valoare_de_inventar else 0 end),2),0) as c24, 
	isnull(round(sum(case when categoria='3' then valoare_de_inventar else 0 end),2),0) as c3, 
	isnull(round(sum(case when categoria='7' then valoare_de_inventar else 0 end),2),0) as c7, 
	isnull(round(sum(case when categoria='8' then valoare_de_inventar else 0 end),2),0) as c8, 
	isnull(round(sum(case when categoria='9' then valoare_de_inventar else 0 end),2),0) as c9, 
	2 as nr 
from #coresp_transferuri where (isnull(@locm,'')='' and 1=0 or lm_primitor like @locm+'%')
union all	-->	iesiri
select 'Iesiri in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii, 
	isnull(round(sum(case when categoria='1' then valoare_de_inventar else 0 end),2),0) as c1, 
	isnull(round(sum(case when categoria='21' then valoare_de_inventar else 0 end),2),0) as c21, 
	isnull(round(sum(case when categoria='22' then valoare_de_inventar else 0 end),2),0) as c22, 
	isnull(round(sum(case when categoria='23' then valoare_de_inventar else 0 end),2),0) as c23, 
	isnull(round(sum(case when categoria='24' then valoare_de_inventar else 0 end),2),0) as c24, 
	isnull(round(sum(case when categoria='3' then valoare_de_inventar else 0 end),2),0) as c3, 
	isnull(round(sum(case when categoria='7' then valoare_de_inventar else 0 end),2),0) as c7, 
	isnull(round(sum(case when categoria='8' then valoare_de_inventar else 0 end),2),0) as c8, 
	isnull(round(sum(case when categoria='9' then valoare_de_inventar else 0 end),2),0) as c9, 
	3 as nr 
from #coresp_transferuri where (isnull(@locm,'')='' and 1=0 or lm_predator like @locm+'%')
	-->	completare amortizari din transferurile intre subunitati (TSE):
insert into #mfa_categ (explicatii, c1,c21,c22,c23, c24, c3,c7,c8,c9,nr)
select 'Amortizare intrari in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii, 
	isnull(round(sum(case when categoria='1' then [valoare intrari] else 0 end),2),0) as c1, 
	isnull(round(sum(case when categoria='21' then [valoare intrari] else 0 end),2),0) as c21, 
	isnull(round(sum(case when categoria='22' then [valoare intrari] else 0 end),2),0) as c22, 
	isnull(round(sum(case when categoria='23' then [valoare intrari] else 0 end),2),0) as c23, 
	isnull(round(sum(case when categoria='24' then [valoare intrari] else 0 end),2),0) as c24, 
	isnull(round(sum(case when categoria='3' then [valoare intrari] else 0 end),2),0) as c3, 
	isnull(round(sum(case when categoria='7' then [valoare intrari] else 0 end),2),0) as c7, 
	isnull(round(sum(case when categoria='8' then [valoare intrari] else 0 end),2),0) as c8, 
	isnull(round(sum(case when categoria='9' then [valoare intrari] else 0 end),2),0) as c9,
	3 as nr
from #amortizari_transferuri union all
select 'Amortizare cedata la iesiri in perioada '+convert(varchar ,@datajos,103)+' - '+ convert(varchar ,@datasus,103)as Explicatii, 
	isnull(round(sum(case when categoria='1' then [valoare iesiri] else 0 end),2),0) as c1, 
	isnull(round(sum(case when categoria='21' then [valoare iesiri] else 0 end),2),0) as c21, 
	isnull(round(sum(case when categoria='22' then [valoare iesiri] else 0 end),2),0) as c22, 
	isnull(round(sum(case when categoria='23' then [valoare iesiri] else 0 end),2),0) as c23, 
	isnull(round(sum(case when categoria='24' then [valoare iesiri] else 0 end),2),0) as c24, 
	isnull(round(sum(case when categoria='3' then [valoare iesiri] else 0 end),2),0) as c3, 
	isnull(round(sum(case when categoria='7' then [valoare iesiri] else 0 end),2),0) as c7, 
	isnull(round(sum(case when categoria='8' then [valoare iesiri] else 0 end),2),0) as c8, 
	isnull(round(sum(case when categoria='9' then [valoare iesiri] else 0 end),2),0) as c9,
	4 as nr
from #amortizari_transferuri
	--> trimiterea rezultatelor:
select explicatii,tip, c1,c21,c22,c23,c24,c3,c7,c8,c9, c1+c21+c22+c23+c24+c3+c7+c8+c9 as total from ( 
select max(explicatii) explicatii, sum(c1) c1,sum(c21) c21,sum(c22) c22,sum(c23) c23,sum(c24) c24,
		sum(c3) c3,sum(c7) c7, sum(c8) c8,sum(c9) c9,'Inventar' as tip from #mf_categ
group by nr 
union all 
select 'Valoare de inventar la '+convert(varchar ,@datasus,103) as Explicatii, 
	sum(case when nr<>3 then c1 else -c1 end) as c1, 
	sum(case when nr<>3 then c21 else -c21 end) as c21, 
	sum(case when nr<>3 then c22 else -c22 end) as c22, 
	sum(case when nr<>3 then c23 else -c23 end) as c23, 
	sum(case when nr<>3 then c24 else -c24 end) as c24, 
	sum(case when nr<>3 then c3 else -c3 end) as c3, 
	sum(case when nr<>3 then c7 else -c7 end) as c7, 
	sum(case when nr<>3 then c8 else -c8 end) as c8, 
	sum(case when nr<>3 then c9 else -c9 end) as c9, 
	'Inventar' as tip from #mf_categ 
union all 
select max(explicatii) explicatii, sum(c1),sum(c21),sum(c22),sum(c23),sum(c24),sum(c3),sum(c7),
	sum(c8),sum(c9),'Amortizare' as tip from #mfa_categ 
group by nr
union all 
select 'Amortizare cumulata la '+convert(varchar ,@datasus,103) as Explicatii, 
	sum(case when nr<>4 then c1 else -c1 end) as c1, 
	sum(case when nr<>4 then c21 else -c21 end) as c21, 
	sum(case when nr<>4 then c22 else -c22 end) as c22, 
	sum(case when nr<>4 then c23 else -c23 end) as c23, 
	sum(case when nr<>4 then c24 else -c24 end) as c24, 
	sum(case when nr<>4 then c3 else -c3 end) as c3, 
	sum(case when nr<>4 then c7 else -c7 end) as c7, 
	sum(case when nr<>4 then c8 else -c8 end) as c8, 
	sum(case when nr<>4 then c9 else -c9 end) as c9, 
	'Amortizare' as tip from #mfa_categ 
)z 
 
if object_id('tempdb.dbo.#patrimonii') is not null drop table #patrimonii --> prefiltrare pt #fisamf
if object_id('tempdb.dbo.#fisamf') is not null drop table #fisamf	--> prefiltrare pt #val_inventar
if object_id('tempdb.dbo.#val_inventar') is not null drop table #val_inventar	--> baza pt valorile de inventar si #val_amortizare
if object_id('tempdb.dbo.#mf_categ') is not null drop table #mf_categ	--> valorile de inventar pe categorii
if object_id('tempdb.dbo.#mfa_categ') is not null drop table #mfa_categ	--> amortizarile pe categorii
if object_id('tempdb.dbo.#coresp_transferuri') is not null drop table #coresp_transferuri	--> calcul valori de inventar din TSE
if object_id('tempdb.dbo.#amortizari_transferuri') is not null drop table #amortizari_transferuri	-->	calcul amortizari din TSE

if object_id('tempdb.dbo.#teste') is not null
begin
	select * from #teste
	drop table #teste
end
