--***
create procedure rapFisaContuluiBalanta(@DataJos datetime,@DataSus datetime,@Cont varchar(40),@loc_de_munca varchar(9)=null,
		@tip int,	-- 1=cumulat, 0=perioada
		@desfasurare int=0, @cusoldrulaj int=0,
		@centralizare int=1)
/*	-- pt teste
declare @DataJos datetime,@DataSus datetime,@Cont varchar(40),@loc_de_munca varchar(9),@tip int, @cusoldrulaj int,
		@centralizare int
	select @DataJos='2011-1-1' , @DataSus='2011-1-31' , @Cont='442' --, @loc_de_munca='%' 
			,@tip=0 , @desfasurare=2, @cusoldrulaj=1, @centralizare=1
--*/
as
declare @eroare varchar(1000)
set @eroare=''
begin try
	--exec fainregistraricontabile @datasus=@DataSus
	set transaction isolation level read uncommitted
	declare @q_DataJos datetime,@q_DataSus datetime,@q_Cont varchar(40),@q_loc_de_munca varchar(9),@q_tip int,  @q_cusoldrulaj int,
			@q_centralizare int
	select @q_DataJos=@DataJos , @q_DataSus=@DataSus , @q_Cont=rtrim(isnull(@Cont,''))+'%' , 
			@q_loc_de_munca=rtrim(replace(@loc_de_munca,'|',''))+
							(case when charindex('|',@loc_de_munca)>0 then '' else '%' end)
		, @q_tip=@tip ,  @q_cusoldrulaj=@cusoldrulaj, @q_centralizare=@centralizare
--	select @q_loc_de_munca
	declare @dataanj datetime,@ccont varchar(40),@lm1 varchar(9),@mindata datetime,@q_tipc char(1), @lminch int
	set @dataanj=(case when @q_tip=1 then dateadd(day,1-datepart(dayofyear,@q_DataJos),@q_DataJos) else @q_DataJos end)
	set @mindata=(case when @dataanj<@q_DataJos then @dataanj  else @q_DataJos end)

	if object_id('tempdb.dbo.#conturi') is not null drop table #conturi
	if object_id('tempdb.dbo.#tempsolduri') is not null drop table #tempsolduri
	if object_id('tempdb.dbo.#temprul') is not null drop table #temprul
	if object_id('tempdb.dbo.#final') is not null drop table #final

	select x.cont_parinte, max(x.denumire_cont) denumire_cont, x.cont,
		max(x.tip_cont) tip_cont, x.are_analitice, 0 as nivel 
	into #conturi
	from
	(
	select x.cont_parinte, x.denumire_cont,x.cont,x.tip_cont,x.are_analitice
		from conturi x where rtrim(@q_cont) like rtrim(x.Cont)+'%' and rtrim(x.cont)<>rtrim(@q_cont)
		union all
	select x.cont_parinte, x.denumire_cont,x.cont,x.tip_cont,x.are_analitice
		from conturi x where rtrim(x.cont) like @q_Cont+'%' and rtrim(x.cont)<>rtrim(@q_cont)
	)x	group by x.cont_parinte, x.cont,x.are_analitice

	declare @utilizator varchar(20), @eLmUtiliz int
	select @utilizator=dbo.fIaUtilizator('')
	declare @LmUtiliz table(valoare varchar(200))
	insert into @LmUtiliz(valoare)
	select cod from lmfiltrare where utilizator=@utilizator
	set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)
		
	declare @nivel int
	set @nivel=1
	update #conturi set nivel=1 where  ISNULL(cont_parinte,'')=''

	while exists (select 1 from #conturi where nivel=0)
	begin
		update #conturi set nivel=c.nivel+1 from #conturi, #conturi c where c.cont=#conturi.cont_parinte and c.nivel=@nivel
		set @nivel=@nivel+1
	end
	declare @RulPeLocm int
	select @RulPeLocm=isnull((select val_logica from par where tip_parametru='GE' and parametru='RULAJELM'), 0)

	set @eLmUtiliz=(case when @RulPeLocm=0 then 0 else @eLmUtiliz end) --> conditia are sens doar daca este 

	create table #tempsolduri(cont varchar(40),tip_cont char(1),loc_de_munca char(9),sold_debit float,sold_credit float)
	declare crsor cursor for
	select a.cont,max(a.tip_cont) as tip_cont,(case when @rulpelocm=0 then '' else p.loc_de_munca end)
			loc_de_munca,
			isnull((select max(1) from proprietati p1 
				where p1.cod_proprietate='LMINCHCONT' and p1.tip='LM' and p1.valoare='1' and 
						p1.cod=(case when @rulpelocm=0 then '' else p.loc_de_munca end)),1-@rulpelocm) as lminch
		from #conturi a inner join
			(select cont_debitor as cont,loc_de_munca from pozincon union all
			 select cont_creditor as cont,loc_de_munca from pozincon union all
			 select cont,loc_de_munca from rulaje
				) p on a.cont=p.cont
			where (@rulpelocm=0 or @rulpelocm<>0 and p.loc_de_munca<>'')
			and (@q_loc_de_munca is null or rtrim(p.loc_de_munca) like @q_loc_de_munca)
			and a.are_analitice=0
			and a.cont<'8'
				and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=p.Loc_de_munca))
			group by a.cont,(case when @rulpelocm=0 then '' else p.loc_de_munca end)
	open crsor
	fetch next from crsor into @ccont,@q_tipc,@lm1, @lminch
	while @@fetch_status=0
	begin
		insert into #tempsolduri
		select @ccont,@q_tipc,@lm1,sold_debitor,sold_creditor
			from (select * from dbo.solduricont (@ccont,null,@dataanj,null,@lm1)) as a
			where (@lminch=1 or @RulPeLocm=0)
			union all
			select @ccont,@q_tipc,@lm1,0,0
			where (@lminch=0 and @RulPeLocm=1)
		fetch next from crsor into @ccont,@q_tipc,@lm1, @lminch
	end
	close crsor
	deallocate crsor

	select isnull(p1.cont_creditor,p2.cont_debitor) as cont,(case when @RulPeLocm=1 then isnull(p1.loc_de_munca,p2.loc_de_munca) else '' end) as loc_de_munca,
			isnull(p1.rulajc_perioada,0) rulajc_perioada,isnull(p2.rulajd_perioada,0) rulajd_perioada,
			isnull(p1.rulajc_cumulat,0) rulajc_cumulat,isnull(p2.rulajd_cumulat,0) rulajd_cumulat
				into #temprul
	 from	(select sum(case when p1.data between @q_DataJos and @q_DataSus then p1.suma else 0 end) as rulajc_perioada,
			sum(case when p1.data between @mindata and @q_DataSus then p1.suma else 0 end) as rulajc_cumulat
			,cont_creditor,loc_de_munca from pozincon p1
			where data between @mindata and @q_DataSus and (@q_loc_de_munca is null or rtrim(isnull(loc_de_munca,'')) like @q_loc_de_munca)
				and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=Loc_de_munca))
			group by cont_creditor,loc_de_munca) p1 full join
		(select sum(case when p2.data between @q_DataJos and @q_DataSus then p2.suma else 0 end) as rulajd_perioada,
			sum(case when p2.data between @mindata and @q_DataSus then p2.suma else 0 end) as rulajd_cumulat
			,cont_debitor,loc_de_munca from pozincon p2
			where data between @mindata and @q_DataSus and (@q_loc_de_munca is null or rtrim(isnull(loc_de_munca,'%')) like @q_loc_de_munca)
				and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=Loc_de_munca))
			group by cont_debitor,loc_de_munca) p2
				on p2.cont_debitor=p1.cont_creditor and p1.loc_de_munca=p2.loc_de_munca

	select isnull(t.loc_de_munca,'') as cod,isnull(t.loc_de_munca,'') loc_de_munca, isnull(t.cont,'') as parinte,max(lm.denumire) as denumire,isnull(max(t.tip_cont),'B') as tip_cont,
				max(t.sold_debit) as sold_debit,max(t.sold_credit) as sold_credit
				,sum(tr.rulajc_perioada) as rulajc_perioada
				,sum(tr.rulajd_perioada) as rulajd_perioada
				,sum(tr.rulajc_cumulat) as rulajc_cumulat
				,sum(tr.rulajd_cumulat) as rulajd_cumulat,isnull(MAX(c.Nivel)+1,0) as nivel, 1 as detaliu,0 as parcurs,
				MAX(ABS(isnull(t.sold_debit,0)))+MAX(ABS(isnull(t.sold_credit,0))) as abssold,
				sum(abs(isnull(tr.rulajc_perioada,0))+abs(isnull(tr.rulajd_perioada,0))+abs(isnull(tr.rulajc_cumulat,0))+ABS(isnull(tr.rulajd_cumulat,0))) as absrulaj,
				max(isnull(lm.Cod_parinte,'')) as LMparinte, convert(decimal(15,2),0) sold_initial
				into #final
			from 	#tempsolduri t
				inner join #conturi c on c.cont=t.cont
				left join #temprul tr on tr.cont=t.cont and t.loc_de_munca=tr.loc_de_munca
				left join lm on lm.cod=isnull(t.loc_de_munca,tr.loc_de_munca)
				--left join #conturi c on c.cont=t.cont
	where (@q_loc_de_munca is null or rtrim(t.loc_de_munca) like @q_loc_de_munca)
			and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=t.Loc_de_munca))
	group by t.cont, t.loc_de_munca, substring(t.cont,1,1)
	union all
	select c.cont, '',
		(case when max(c.cont_parinte)='' then 'C'+left(c.cont,1) else max(c.cont_parinte) end),
		max(c.denumire_cont),max(c.tip_cont),0,0,0,0,0,0,max(c.nivel) as nivel, 0 as detaliu, 0 as parcurs, 0 as abssold, 0 as absrulaj, '' LMparinte,0
			from #conturi c
	group by c.cont
	union all
	select 'C'+left(c.cont,1), '',
		'Total','Clasa '+left(c.cont,1),'B',0,0,0,0,0,0,0 as nivel, 0 as detaliu, 0 as parcurs, 0 as abssold, 0 as absrulaj, '' LMparinte,0
			from #conturi c-- left join #tempsolduri t on c.cont=t.cont
	group by left(c.cont,1)
	union all
	select 'Total', '',
		null,'Total','B',0,0,0,0,0,0,-1 as nivel, 0 as detaliu, 0 as parcurs, 0 as abssold, 0 as absrulaj, '' LMparinte,0
	update #final set
			sold_debit=isnull(sold_debit,0), sold_credit=isnull(sold_credit,0), rulajc_perioada=isnull(rulajc_perioada,0),
			rulajd_perioada=isnull(rulajd_perioada,0), rulajc_cumulat=isnull(rulajc_cumulat,0), rulajd_cumulat=isnull(rulajd_cumulat,0)
			
	update #final set parcurs=1 where detaliu=1
	update #final set parcurs=1 where not exists (select 1 from #final f where f.detaliu=1 and f.parinte=#final.cod and f.nivel-1=#final.nivel)
		and not exists (select 1 from #final f where f.parinte=#final.cod and f.nivel-1=#final.nivel)

-->	calculez totalurile:
	while exists (select 1 from #final where parcurs=0 and LMparinte='') 
		update #final set
			sold_debit=f.sold_debit, sold_credit=f.sold_credit, rulajc_perioada=f.rulajc_perioada,
			rulajd_perioada=f.rulajd_perioada, rulajc_cumulat=f.rulajc_cumulat, rulajd_cumulat=f.rulajd_cumulat,
			abssold=f.abssold, absrulaj=f.absrulaj, parcurs=1
			from (select sum(f.sold_debit)as sold_debit, sum(f.sold_credit) as sold_credit, sum(f.rulajc_perioada) as rulajc_perioada,
				SUM(f.rulajd_perioada) as rulajd_perioada, SUM(f.rulajc_cumulat) as rulajc_cumulat, SUM(f.rulajd_cumulat) as rulajd_cumulat
						,SUM(abssold) as abssold, SUM(absrulaj) as absrulaj,parinte,nivel from #final f 
					where f.parcurs=1 --and (f.LMparinte='' or @q_tip=1)
						group by parinte,nivel) f
						where f.parinte=#final.cod and f.nivel-1=#final.nivel and #final.LMparinte=''
							and not exists (select 1 from #final p where p.parinte=#final.cod and p.parcurs=0)

	update #final set tip_cont=f.tip_cont
		from (select (case  when MAX(tip_cont)='A' and MIN(tip_cont)='A' then 'A'
							when MAX(tip_cont)='P' and MIN(tip_cont)='P' then 'P'
							else 'B' end
					 ) as tip_cont, parinte from #final f where nivel=1 group by parinte) f where f.parinte=#final.cod and #final.nivel=0
					 
	update #final set tip_cont=f.tip_cont
		from (select (case  when MAX(tip_cont)='A' and MIN(tip_cont)='A' then 'A'
							when MAX(tip_cont)='P' and MIN(tip_cont)='P' then 'P'
							else 'B' end
					 ) as tip_cont, parinte from #final f where nivel=0 group by parinte) f where f.parinte=#final.cod and #final.nivel=-1
	update #final set sold_initial=sold_debit-sold_credit
	select
			cod, loc_de_munca, parinte, denumire, tip_cont, sold_debit, sold_credit, rulajc_perioada, rulajd_perioada, 
			rulajc_cumulat, rulajd_cumulat, nivel, detaliu, sold_initial,
			(case tip_cont when 'A' then sold_initial when 'P' then 0 else (case when sold_initial>0 then sold_initial else 0 end) end) sold_initial_debit, 
			-(case tip_cont when 'P' then sold_initial when 'A' then 0 else (case when sold_initial>0 then sold_initial else 0 end) end)	sold_initial_credit
			from #final 
		where (@q_centralizare=2 or detaliu=0)
			and (@q_cusoldrulaj=0 or
				 @q_cusoldrulaj=1 and absrulaj>0 or abssold>0)
		order by nivel, len(cod), cod

end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (rapFisaContuluiBalanta)'
end catch

if object_id('tempdb.dbo.#conturi') is not null drop table #conturi
if object_id('tempdb.dbo.#tempsolduri') is not null drop table #tempsolduri
if object_id('tempdb.dbo.#temprul') is not null drop table #temprul
if object_id('tempdb.dbo.#final') is not null drop table #final
if object_id('tempdb.dbo.#test') is not null
	begin
		select * from #test
		drop table #test
	end

if len(@eroare)>0 raiserror(@eroare,16,1)
