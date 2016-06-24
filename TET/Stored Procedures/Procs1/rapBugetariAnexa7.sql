--***
create procedure [dbo].[rapBugetariAnexa7] (@datajos datetime,@datasus datetime,@prefix varchar(40),
			@comp_ec varchar(20)=null, @ign_pb nvarchar(1),@grupa varchar(20), 
			@nivCent varchar(20), @locm varchar(9), @doar_sume int, @in_tabela_temporara int=0
			,@cont varchar(13)=null,@cont_debitor varchar(13)=null,@cont_creditor varchar(13)=null, @valuta varchar(3)=null,
			@anexa varchar(1)='7')
as
begin
/*	Executia bugetara Anexa 7 (si 14): script
declare @datajos datetime,@datasus datetime,@prefix nvarchar(4000),@ign_pb nvarchar(1),@grupa varchar(20), @nivCent varchar(20), @locm varchar(9),
		@doar_sume int
select @datajos='2011-01-01 00:00:00',@datasus='2011-6-28 00:00:00',
	--@prefix='1 0 ',
		@ign_pb=N'0',@grupa=null, 
	@nivCent='2,4,8,10,12,14,16', @doar_sume=1
--*/	/*@  */--> nu stiu ce inseamna si cum s-ar inlocui
	declare @niveleCentralizare varchar(20)
	set @niveleCentralizare='4,6,8,10,12,14,16'
set @nivCent=(case when isnull(@nivCent,'')='' then @niveleCentralizare else @nivCent end)
declare @q_datajos datetime,@q_datasus datetime, @q_prefix varchar(20),@q_ign_pb bit,@problema bit, @q_grupa varchar(20),
		@q_doar_sume int, @masca varchar(18)
select @q_datajos=@datajos, @q_datasus=@datasus, @q_prefix=rtrim(isnull(@prefix,'')), @q_ign_pb=@ign_pb, @problema=0, @q_grupa=@grupa,
		@q_doar_sume=@doar_sume

if(@anexa='6' and charindex(',',@nivcent)=0)
	set @nivcent=substring(@niveleCentralizare,1,charindex(','+rtrim(@nivCent),','+@niveleCentralizare+',')+len(@nivCent))
set @masca=@q_prefix+REPLICATE('X',18-LEN(@q_prefix))	/**	cu @masca si @nivcent stabilesc centralizarea datelor*/
set @q_prefix=replace(@q_prefix,'X','_')
set @comp_ec=rtrim(@comp_ec)
if (len(@comp_ec)>0)
	set @masca=left(@masca,8)+rtrim(@comp_ec)+substring(@masca,8+len(@comp_ec)+1,len(@masca))
--test	select @nivcent		select @masca
declare @fPrefNumar bit	set @fPrefNumar=0		/**	ceva specific PRIMTM	*/
select @fPrefNumar=1-val_logica from par where tip_parametru='SP' and parametru='PRIMTIM'

	/** daca nu se ruleaza fortat raportul (@ign_pb=1) si se gasesc probleme la configurarea legaturilor dintre indicatori se anuleaza rularea rap.: */
if @q_ign_pb=0 and exists (select 1 from indbugcomp p where not exists (select 1 from indbug c where c.indbug=p.compindbug or p.compindbug='') 
								and exists (select 1 from indbug c where c.indbug=p.indbug))
begin	set @problema=1
	insert into #tmp(denumire, cod, prev_bug_init, prev_bug_trim_def, ang_bug, ang_leg, pl_ef, chelt_ef, tip_pb) 
				select rtrim(p.comanda) as denumire, p.cod_produs as cod, 0 as prev_bug_init, 
				0 as prev_bug_trim_def, 0 as ang_bug, 0 as ang_leg, 0 as pl_ef, 0 as chelt_ef, 1 as tip_pb
			from pozcom p where not exists (select 1 from comenzi c where c.comanda=p.cod_produs or p.cod_produs='') and p.Subunitate<>'GR'
		and exists (select 1 from comenzi c where c.comanda=p.comanda)
	goto final
end

	/**	Pregatire filtrare pe proprietati utilizatori*/
declare @eLmUtiliz int
declare @LmUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
insert into @LmUtiliz(valoare, cod_proprietate)
select valoare, cod_proprietate from fPropUtiliz(null) where valoare<>'' and cod_proprietate='LOCMUNCA'
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
	/**	organizare indicatori pentru a fi mai usor in continuare - in principal, pentru a lua grupa indicatorilor */
select c.indbug, c.denumire as descriere,
		rtrim(g.compindbug) as grupa,
		rtrim(dg.Denumire_grupa) as nume_grupa
		into #indicatori from indbug c 
			left join indbugcomp g on g.indbug=c.indbug
			left join indbuggr dg on dg.Grupa=g.compindbug
		where (rtrim(c.indbug) like rtrim(@q_prefix)+'%') and (@q_grupa is null or ISNULL(g.compindbug,'')=@q_grupa)
			and (@comp_ec is null or substring(c.indbug,9,len(c.indbug)) like @comp_ec+'%')

insert into #indicatori 
select c.indbug,
		max(c.denumire) as descriere, 
		max(rtrim(g.compindbug)) as grupa,
		max(rtrim(dg.Denumire_grupa)) as nume_grupa
		from indbug c 
			inner join #indicatori cc on rtrim(cc.indbug) like rtrim(c.indbug)+'%' and c.indbug<>cc.indbug
			left join indbugcomp g on g.indbug=c.indbug
			left join indbuggr dg on dg.Grupa=g.compindbug
	where not exists (Select 1 from #indicatori c1 where c.indbug=c1.indbug)
	group by c.indbug
	/**	se iau sumele, conform regulilor stabilite pentru bugetari */
select max(c.descriere) as denumire,rtrim(c.indbug) as cod 
		,sum(case when p.cont_debitor='8060' and  ((@fprefNumar=0 or left(numar_document,2)='ba') and year(data) between year(@q_datajos) and year(@q_datasus) 
					or (@fprefNumar=0 or left(numar_document,2)='rb') and (datepart(quarter,data)<=datepart(quarter,@q_datasus) or year(data)<year(@q_datasus)))
					then suma else 0 end) as prev_bug_init
		,sum(case when p.cont_debitor='8060' and  (@fprefNumar=0 or left(numar_document,2)='ba' or left(numar_document,2)='rb') and 
			(datepart(quarter,data)<=datepart(quarter,@q_datasus) or year(data)<year(@q_datasus))
		 then suma else 0 end) as prev_bug_trim_def
		,sum(case when data between @q_datajos and @q_datasus and cont_debitor='8066' then suma else 0 end) as ang_bug
		,sum(case when data between @q_datajos and @q_datasus and cont_debitor='8067' then suma else 0 end) as ang_leg
		,sum(case when data between @q_datajos and @q_datasus and cont_creditor='8067' then suma else 0 end) as pl_ef
		,sum((case when cont_creditor like '6%' then -1 else 1 end)*
			(case when data between @q_datajos and @q_datasus and 
				(cont_debitor like '6%' or cont_creditor like '6%' and cont_debitor not like '121%') and tip_document<>'IC' then suma else 0 end)
			) as chelt_ef
		,0 as tip_pb
	into #an7 from #indicatori c left join pozincon p on substring(p.comanda,21,20)=c.indbug and year(isnull(data,@q_datajos)) between year(@q_datajos) and year(@q_datasus)
			and (@locm is null or p.Loc_de_munca like @locm+'%')
			and (@cont is null or p.cont_debitor like @cont+'%' or p.cont_creditor like @cont+'%')
			and (@cont_debitor is null or p.cont_debitor like @cont_debitor+'%')
			and (@cont_creditor is null or p.cont_creditor like @cont_creditor+'%')
			and (@valuta is null or p.Valuta=@valuta)
			and (@eLmUtiliz=0 or p.Loc_de_munca='' or exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca))
	where  year(isnull(data,@q_datajos)) between year(@q_datajos) and year(@q_datasus) and dbo.indicatorCheltuieli(c.indbug)=1--and left(c.comanda,1)>='1'
group by c.indbug
order by c.indbug

	/**	elimin sumele de pe nivelele superioare pentru a nu incurca in continuare*/
update #an7 set prev_bug_init=0, prev_bug_trim_def=0, ang_bug=0, ang_leg=0, pl_ef=0, chelt_ef=0
where exists(select 1 from #an7 b where len(rtrim(b.cod))>len(rtrim(#an7.cod)) and rtrim(b.cod) like rtrim(#an7.cod)+'%') or cod not like @q_prefix+'%'
	/**	urmeaza calculul sumelor in sus, pe arborele indicatorilor*/
select top 0 * into #tmp from #an7
--/*
declare @q_lung int,@iterator int,@nr_randuri int,@bucla_nesfarsita bit set @q_lung=16 set @iterator=0 set @bucla_nesfarsita=0
while (select count(*) from #an7)>0 and @iterator<100 and @q_lung>0
begin
	delete from #an7 from #an7 a, #tmp t where a.cod=t.cod
	insert into #tmp 
		select max(a.denumire) ,a.cod ,sum(a.prev_bug_init)+sum(isnull(t.prev_bug_init,0))
				,sum(a.prev_bug_trim_def)+sum(isnull(t.prev_bug_trim_def,0))
				,sum(a.ang_bug)+sum(isnull(t.ang_bug,0)) 
				,sum(a.ang_leg)+sum(isnull(t.ang_leg,0)) 
				,sum(a.pl_ef)+sum(isnull(t.pl_ef,0)) 
				,sum(a.chelt_ef)+sum(isnull(t.chelt_ef,0)),0 as tip_pb
			from #an7 a left join #tmp t on left(t.cod,len(rtrim(t.cod))-2)=a.cod and not exists(select 1 from indbugcomp p where t.cod=p.compindbug
											and p.indbug<>p.compindbug and p.compindbug<>'')
			where not exists(select 1 from indbugcomp p where a.cod=p.indbug and p.indbug<>p.compindbug and p.compindbug<>'')
					and len(a.cod) between @q_lung-1 and @q_lung
		group by a.cod
	while (select count(*) from #an7 where len(rtrim(cod)) between @q_lung-1 and @q_lung)>0 and 
		@nr_randuri<(select count(*) from #tmp where len(rtrim(cod)) between @q_lung-1 and @q_lung)
	begin
		set @nr_randuri=(select count(*) from #an7 where len(rtrim(cod)) between @q_lung-1 and @q_lung)
		delete from #an7 from #an7 a, #tmp t where a.cod=t.cod
		insert into #tmp 
			select
				max(a.denumire) ,a.cod ,sum(t.prev_bug_init) ,sum(t.prev_bug_trim_def) ,sum(t.ang_bug) ,sum(t.ang_leg) ,sum(t.pl_ef) 
				,sum(t.chelt_ef),0 as tip_pb
				from #an7 a inner join indbugcomp p on a.cod=p.indbug and p.indbug<>p.compindbug and p.compindbug<>''
							inner join #tmp t on p.compindbug=t.cod
					   where len(rtrim(a.cod)) between @q_lung-1 and @q_lung
		group by a.cod
	end
	if (@nr_randuri=(select count(*) from #tmp where len(rtrim(cod)) between @q_lung-1 and @q_lung)) set @bucla_nesfarsita=1
	set @iterator=@iterator+1
	set @q_lung=@q_lung-2
end
if	((@iterator=100 or @bucla_nesfarsita=1) and @q_ign_pb=0)
begin
	set @problema=1
	truncate table #tmp
	insert into #tmp(denumire, cod, prev_bug_init, prev_bug_trim_def, ang_bug, ang_leg, pl_ef, chelt_ef, tip_pb) 
			select 'Problema nedeterminata' as denumire, 'bucla infinita' as cod, 0 as prev_bug_init, 
			0 as prev_bug_trim_def, 0 as ang_bug, 0 as ang_leg, 0 as pl_ef, 0 as chelt_ef, 2 as tip_pb
end
--*/

final:	--se grupeaza sumele in functie de nivelele de centralizare selectate:
select rtrim(case when max(denumire)=MIN(denumire) then max(denumire) else '----' end) as denumire, max(cod1) as cod1, max(cod) as cod, 
		sum(prev_bug_init) as prev_bug_init, sum(prev_bug_trim_def) as prev_bug_trim_def, sum(ang_bug) as ang_bug, sum(ang_leg) as ang_leg, 
		sum(pl_ef) as pl_ef, sum(chelt_ef) as chelt_ef, max(tip_pb) as tip_pb, max(grupa) as grupa, rtrim(max(nume_grupa)) as nume_grupa, 
		max(codGrupare) as codGrupare into #final
from
(
select rtrim(max(t.denumire)) denumire,max(cod) as cod1,max(rtrim(case when len(cod)<=8 then '' 
		else right(rtrim(substring(cod,9,15)),6) end)) as cod
		,max(prev_bug_init) prev_bug_init,max(prev_bug_trim_def) prev_bug_trim_def,max(ang_bug) ang_bug,max(ang_leg) ang_leg,
			max(pl_ef) pl_ef,max(chelt_ef) chelt_ef,max(tip_pb) tip_pb,max(c.grupa) grupa,
			max(c.nume_grupa) nume_grupa,
		max((case when CHARINDEX(',4,',','+@nivCent+',')>0 then substring(indbug,1,4) else substring(@masca,1,4) end)+
		(case when CHARINDEX(',6,',','+@nivCent+',')>0 then substring(indbug,5,2) else substring(@masca,5,2) end)+
		(case when CHARINDEX(',8,',','+@nivCent+',')>0 then substring(indbug,7,2) else substring(@masca,7,2) end)+
		(case when CHARINDEX(',10,',','+@nivCent+',')>0 then substring(indbug,9,2) else substring(@masca,9,2) end)+
		(case when CHARINDEX(',12,',','+@nivCent+',')>0 then substring(indbug,11,2) else substring(@masca,11,2) end)+
		(case when CHARINDEX(',14,',','+@nivCent+',')>0 then substring(indbug,13,2) else substring(@masca,13,2) end)+
		(case when CHARINDEX(',16,',','+@nivCent+',')>0 then substring(indbug,15,2) else substring(@masca,15,2) end)) as codGrupare
		from #tmp t
	inner join #indicatori c on c.indbug=t.cod
	where cod like rtrim(@q_prefix)+'%' --and len(cod)>8
			--and (@comp_ec is null or substring(cod,9,len(cod)) like @comp_ec+'%')
			and (@nivCent is null or CHARINDEX(','+rtrim(convert(varchar(2),
					 ROUND(((case when LEN(indbug)<4 then 4 else LEN(indbug) end)+1)/2,0)*2
					))+',',','+@nivCent+',')>0)
			or (@problema=1 and @q_ign_pb=0)
	group by cod
) z where (@q_doar_sume=0 or abs(isnull(prev_bug_init,0))+abs(isnull(prev_bug_trim_def,0))+abs(isnull(ang_bug,0))+
							abs(isnull(ang_leg,0))+abs(isnull(pl_ef,0))+abs(isnull(chelt_ef,0))>0
			)
	group by codGrupare
order by codGrupare

	/**	daca se foloseste tabela temporara (apel din anexa14) scrie in tabela, altfel aduce datele direct */
if (@in_tabela_temporara=0)	
	select denumire, cod1, cod, prev_bug_init, prev_bug_trim_def, ang_bug, ang_leg, pl_ef, chelt_ef, tip_pb, grupa, nume_grupa, codGrupare
	from #final
	order by codGrupare
	else if object_id('tempdb.dbo.tRapBugetariAnexa7') is null
		select denumire, cod1, cod, prev_bug_init, prev_bug_trim_def, ang_bug, ang_leg, pl_ef, chelt_ef, tip_pb, 
			grupa, nume_grupa, codGrupare, host_id() hostid
			into tempdb.dbo.tRapBugetariAnexa7 from #final
			order by codGrupare
		else begin delete from tempdb.dbo.tRapBugetariAnexa7 where hostid=host_id()
				insert into tempdb.dbo.tRapBugetariAnexa7(denumire, cod1, cod, prev_bug_init, prev_bug_trim_def, ang_bug, ang_leg, pl_ef, chelt_ef, tip_pb,
															grupa, nume_grupa, codGrupare, hostid)
				select denumire, cod1, cod, prev_bug_init, prev_bug_trim_def, ang_bug, ang_leg, pl_ef, chelt_ef, tip_pb, 
				grupa, nume_grupa, codGrupare, host_id() hostid from #final									
				order by codGrupare
			end
drop table #an7	drop table #tmp drop table #indicatori drop table #final
end
