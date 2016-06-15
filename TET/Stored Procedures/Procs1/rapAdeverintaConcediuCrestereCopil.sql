create procedure rapAdeverintaConcediuCrestereCopil (@sesiune varchar(50), @marca varchar(6), @data datetime, @parXML xml='<row/>')
AS
/*
	exemplu de apel
	exec rapAdeverintaConcediuCrestereCopil '', '133145', '08/01/2013', '<row />'
*/
begin try 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	declare @utilizator varchar(20), @lista_lm int, @datalunii_11 datetime, @datalunii datetime, @dataSfLauzie datetime, 
		@ProcIT1 float, @IT1SuspContr int, @ProcIT2 float, @IT2SuspContr int, @ProcIT3 float, @IT3SuspContr int, @denIntrTehn3 varchar(50)

	if @sesiune<>''
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	else 
		set @utilizator=dbo.fIaUtilizator(null)

	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @datalunii_11=dbo.eom(DateADD(month,-11,@data))
	set @datalunii=dbo.eom(@data)
	set @dataSfLauzie=DateADD(day,41,@data)

--	parametrii pentru perioadele nelucrate (platite sau neplatite - ore intreupere tehnologica 1,2,3)
	select 
		@ProcIT1=max(case when Parametru='PROCINT' then Val_numerica else 0 end),
		@IT1SuspContr=max(case when Parametru='IT1-SUSPC' then Val_logica else 0 end),
		@ProcIT2=max(case when Parametru='PROC2INT' then Val_numerica else 0 end),
		@IT2SuspContr=max(case when Parametru='PROC2INT' then Val_logica else 0 end),
		@ProcIT3=max(case when Parametru='PROC3INT' then Val_numerica else 0 end),
		@IT3SuspContr=max(case when Parametru='PROC3INT' then Val_logica else 0 end),
		@denIntrTehn3=max(case when Parametru='PROC3INT' then Val_alfanumerica else '' end)
	from par 
	where Tip_parametru='PS' and Parametru in ('PROCINT','IT1-SUSPC','PROC2INT','PROC3INT')

--	pun intr-o tabela temporara ultimele 2 suspendari (cea curenta si daca exista una anterioara)
	if object_id('tempdb..#ingrcopil') is not null drop table #ingrcopil
	select * into #ingrcopil from 
	(select Marca, Data_inceput, Data_sfarsit, Data_incetare, RANK() over (partition by Marca order by Data_inceput Desc) as ordine
	from fRevisalSuspendari ('01/01/1901', '12/31/2999', @marca) where Temei_legal in ('Art51Alin1LiteraA','Art51Alin1LiteraB')) a
	where ordine<=2

--	pun intr-o tabela temporara orele de stagiu (lucrate, ore CM, ore CO, ore nelucrate si neplatite)
	if object_id('tempdb..#brutMarca') is not null drop table #brutMarca
	select b.data, b.marca, sum(b.ore_lucrate_regim_normal+isnull(po.ore_platite,0)+b.ore_obligatii_cetatenesti) as ore_lucrate
		,sum(b.ore_concediu_medical) as ore_cm, sum(b.ore_concediu_de_odihna) as ore_co
		,sum(b.ore_concediu_fara_salar+b.ore_nemotivate+b.ore_invoiri+isnull(po.ore_suspendare,0)) as ore_neplatite
		,(case when max(Spor_cond_10)=0 then 8 else max(Spor_cond_10) end) as regim_de_lucru
	into #brutMarca
	from brut b
		left outer join personal p on p.marca=b.marca
		left outer join (select dbo.EOM(po.data) as data, po.Marca, po.Loc_de_munca, 
			sum((case when @ProcIT1<>0 then po.Ore_intrerupere_tehnologica else 0 end)
				+(case when @ProcIT2<>0 then po.ore else 0 end) 
				+(case when @denIntrTehn3<>'' and @ProcIT3<>0 then po.Spor_cond_8 else 0 end)) as ore_platite,
			sum((case when @IT1SuspContr=1 and @ProcIT1=0 then po.Ore_intrerupere_tehnologica else 0 end)
				+(case when @IT2SuspContr=1 and @ProcIT2=0 then po.ore else 0 end) 
				+(case when @denIntrTehn3<>'' and @IT3SuspContr=1 and @ProcIT3=0 then po.Spor_cond_8 else 0 end)) as ore_suspendare
		from pontaj po
			left outer join personal p on p.marca=po.marca
		where data between @datalunii_11 and @datalunii 
			and exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca)
		group by dbo.EOM(po.data), po.marca, po.loc_de_munca) po on po.Marca=b.Marca and po.Data=b.data
	where b.data between @datalunii_11 and @datalunii 
		and exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca)
	group by b.data, b.marca

--	stabilesc perioada de concediu de maternitate aferenta nasterii copilului
	if object_id('tempdb..#maternitate') is not null drop table #maternitate
	select marca, min(data_inceput) as data_inceput, max(data_sfarsit) as data_sfarsit
	into #maternitate
	from conmed
	where marca=@marca and Tip_diagnostic='8-'
		and data between dbo.EOM(DateADD(month,-4,@datalunii)) and dbo.EOM(DateADD(month,4,@datalunii))
	group by marca

--	selectie finala		
	select ROW_NUMBER() OVER(ORDER BY n.Data desc) as nr_crt, 
		(case when n.data=@datalunii then 'luna nasterii copilului' 
			when n.data=dbo.EOM(DateADD(month,-1,@datalunii)) then 'luna anterioara lunii nasterii copilului' 
			else 'luna a '+convert(varchar(10),DateDiff(month,n.Data,@datalunii))+'-a anterioara lunii nasterii copilului' end) as explicatii, 
		month(n.data) as luna, year(n.data) as anul, sum(n.venit_total) as venit_total, 
		sum(n.venit_net+isnull(t.Valoare_tichete,0)) as venit_net, 
		round(sum(b.ore_lucrate/regim_de_lucru),0) as zile_lucrate, round(sum(b.ore_cm/regim_de_lucru),0) as zile_cm, round(sum(b.ore_co/regim_de_lucru),0) as zile_co, 
		round(sum(b.ore_neplatite/regim_de_lucru),0) as zile_neplatite, 
		max(isnull(convert(char(10),m.data_inceput,103),'')) as data_inceput_mat, max(isnull(convert(char(10),m.data_sfarsit,103),'')) as data_sfarsit_mat, 
		max(convert(char(10),@datasflauzie,103)) as data_sfarsit_lauzie, 
		max(isnull(convert(char(10),s2.data_inceput,103),'')) as data_inceput_ant, max(isnull(convert(char(10),s2.data_incetare,103),'')) as data_sfarsit_ant, 
		max(isnull(convert(char(10),s1.data_inceput,103),'')) as data_inceput
	from net n 
		left outer join personal p on p.marca=n.marca
		left outer join infopers ip on ip.marca=n.marca
		left outer join #brutMarca b on b.marca=n.marca and b.data=n.data
		left outer join #maternitate m on m.Marca=n.Marca 
		left outer join #ingrcopil s1 on s1.Marca=n.Marca and s1.ordine=1
		left outer join #ingrcopil s2 on s2.Marca=n.Marca and s2.ordine=2
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=n.loc_de_munca
		outer apply (select Valoare_tichete from fNC_tichete (dbo.iauParLD(n.Data,'PS','DJIMPZTIC'), dbo.iauParLD(n.Data,'PS','DSIMPZTIC'), n.Marca, 1)) t 
	where n.data between @datalunii_11 and @datalunii and n.Data=dbo.EOM(n.Data)
		and exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca)
		and (@lista_lm=0 or lu.cod is not null)
	group by n.data, month(n.data), year(n.data)
	order by n.data desc
end try

begin catch
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE()+ ' (rapAdeverintaConcediuCrestereCopil)'
	raiserror(@mesaj, 11, 1)
end catch
