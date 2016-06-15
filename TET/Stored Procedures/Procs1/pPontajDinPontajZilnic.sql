--***
Create procedure pPontajDinPontajZilnic 
	@datajos datetime, @datasus datetime, @lm varchar(20)=null, @strict int=0, @marca varchar(6)=null, @sesiune varchar(50)=null, @parXML xml=null
as
begin try

	set transaction isolation level read uncommitted
	
	declare @userASIS varchar(50), @ore_luna int, @ScadOS_RN int, @ScadO100_RN int, @mesaj varchar(1000)

	set @userASiS=dbo.fIaUtilizator(null)
	set @ore_luna=(select val_numerica from par_lunari where parametru='ore_luna' and data=dbo.eom(@datasus))

	select @ScadOS_RN=max(case when parametru='OSNRN' then Val_logica else 0 end),
		@ScadO100_RN=max(case when parametru='O100NRN' then Val_logica else 0 end)
	from par where tip_parametru in ('PS') and parametru in ('OSNRN','O100NRN')

	if object_id('tempdb..#regimlucru') is not null drop table #regimlucru
	if object_id('tempdb..#pontaj_zilnic') is not null drop table #pontaj_zilnic

	select marca, rl into #regimlucru
	from fDate_pontaj_automat (@datajos, @datasus, @datasus, 'RL', '', 0, 0) po

	select pz.*--, 0 as ore_supl1, 0 as ore_supl2, 0 as ore_supl3, 0 as ore_supl4
	into #pontaj_zilnic
	from pontaj_zilnic pz
		join personal p on p.marca=pz.marca
		left join istpers i on i.marca=pz.marca and i.data=@datasus
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=isnull(i.loc_de_munca,p.loc_de_munca)
	where pz.data between @datajos and @datasus
		and (nullif(@marca,'') is null or pz.marca=@marca)
		and (nullif(@lm,'') is null or isnull(i.loc_de_munca,p.loc_de_munca) like rtrim(@lm)+(case when @strict=1 then '' else '%' end))
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)

	if exists (select * from sysobjects where name ='pPontajDinPontajZilnicSP')
		exec pPontajDinPontajZilnicSP @datajos=@datajos, @datasus=@datasus, @lm=@lm, @strict=@strict, @parXML=@parXML

	if exists (select * from sysobjects where name ='GenerareConcediiDinPontajZilnic')
		exec GenerareConcediiDinPontajZilnic @datajos=@datajos, @datasus=@datasus, @pMarca=@marca, @pLocm=@lm, @stergere=1, @generare=1, @sesiune=@sesiune, @parXML=@parXML

	select cl.data_lunii, pz.marca, p.loc_de_munca as lm, 
		sum(case when pz.tip_ore in ('OL','OD') and p.tip_salarizare in ('1','3') 
			then (case when @ScadOS_RN=1 then ore when ore>rl.rl then rl.rl else ore end) else 0 end) as ore_regie,
		sum(case when pz.tip_ore in ('OL','OD') and p.tip_salarizare not in ('1','3') 
			then (case when @ScadOS_RN=1 then ore when ore>rl.rl then rl.rl else ore end) else 0 end) as ore_acord,
		sum(case when pz.tip_ore='S1' then pz.ore else 0 end) as ore_supl1, 
		sum(case when pz.tip_ore='S2' then pz.ore else 0 end) as ore_supl2, 
		sum(case when pz.tip_ore='S3' then pz.ore else 0 end) as ore_supl3, 
		sum(case when pz.tip_ore='S4' then pz.ore else 0 end) as ore_supl4, 
		sum(case when pz.tip_ore='NO' then pz.ore else 0 end) as ore_noapte,
		sum(case when pz.tip_ore='OD' and cl.Zi_alfa not in ('Sambata','Duminica') and cs.data is null then rl.rl else 0 end) as ore_diurna,
		sum(case when pz.tip_ore='CM' then pz.ore else 0 end) as ore_cm,
		sum(case when pz.tip_ore='CO' then pz.ore else 0 end) as ore_co,
		sum(case when pz.tip_ore='LP' then pz.ore else 0 end) as ore_intr1,
		sum(case when pz.tip_ore='FS' then pz.ore else 0 end) as ore_cfs,
		sum(case when pz.tip_ore='IN' then pz.ore else 0 end) as ore_invoiri,
		sum(case when pz.tip_ore='NE' then pz.ore else 0 end) as ore_nemotivate,
		sum(case when pz.tip_ore='OB' then pz.ore else 0 end) as ore_obligatii
	into #tmppontaj_zilnic
	from #pontaj_zilnic pz
		join personal p on p.marca=pz.marca
		left join istpers i on i.marca=pz.marca and i.data=@datasus
		left join fcalendar(@datajos, @datasus) cl on cl.Data=pz.data
		left join calendar cs on cs.data=pz.data
		left join #regimlucru rl on rl.marca=pz.marca
	group by cl.data_lunii, pz.marca, p.loc_de_munca
	order by max(p.nume)

	if object_id('tempdb..#ppontaj') is not null
		insert into #ppontaj
		select * from #tmppontaj_zilnic
	else
		select * from #tmppontaj_zilnic
end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
/*
	pPontajDinPontajZilnic '08/01/2015','08/31/2015','',0,null
*/
