--***
Create procedure Declaratia112Asigurati
	(@dataJos datetime, @dataSus datetime, @Marca char(6)=null, @Lm char(9), @Strict int, @SirMarci char(200)=null, @TagAsigurat char(20)=null)
as
Begin try
	set transaction isolation level read uncommitted

	declare @utilizator varchar(20), @lista_lm int, @Bugetari int, @InstPubl int, @Elite int, @Somesana int, @Pasmatex int, @Salubris int, @Colas int, 
		@STOUG28 int, @vSTOUG28 int, @ProcIT1 float, @ProcIT2 float, @ProcIT3 float, @IT1SuspContr int, @IT2SuspContr int, @IT3SuspContr int, @denIntrTehn3 varchar(30), 
		@ScadOSRN int, @ScadO100RN int, @ORegieFaraOS2 int, @NuCAS_H int, @NuCASS_H int, @NuASS_N int, @ASSImpS_K int, @LucrCuDiurneNeimpoz int, 
		@OreLuna int, @pCASIndiv decimal(4,2), @SalMin decimal(7), @SalMediu decimal(7), @Data1_an datetime

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	set @Bugetari=dbo.iauParL('PS','UNITBUGET')
	set @InstPubl=dbo.iauParL('PS','INSTPUBL')
	set @Elite=dbo.iauParL('SP','ELITE')
	set @Somesana=dbo.iauParL('SP','SOMESANA')
	set @Pasmatex=dbo.iauParL('SP','PASMATEX')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	set @Colas=dbo.iauParL('SP','COLAS')
	set @STOUG28=dbo.iauParLL(@dataSus,'PS','STOUG28')
	set @vSTOUG28=(case when @STOUG28=1 and 1=0 then 1 else 0 end)
	set @ProcIT1=dbo.iauParN('PS','PROCINT')
	set @ProcIT2=dbo.iauParN('PS','PROC2INT')
	set @ProcIT3=dbo.iauParN('PS','PROC3INT')	
	set @IT1SuspContr=dbo.iauParL('PS','IT1-SUSPC')
	set @IT2SuspContr=dbo.iauParL('PS','PROC2INT')
	set @IT3SuspContr=dbo.iauParL('PS','PROC3INT')
	set @denIntrTehn3=dbo.iauParA('PS','PROC3INT')
	set @ScadOSRN=dbo.iauParL('PS','OSNRN')
	set @ScadO100RN=dbo.iauParL('PS','O100NRN')
	set @ORegieFaraOS2=dbo.iauParL('PS','OREG-FOS2')
	set @NuCAS_H=dbo.iauParL('PS','NUCAS-H')
	set @NuCAS_H=(case when @NuCAS_H=1 and 1=0 then 1 else 0 end)
	set @NuCASS_H=dbo.iauParL('PS','NUASS-H')
	set @NuASS_N=dbo.iauParL('PS','NUASS-N')
	set @ASSImpS_K=dbo.iauParL('PS','ASSIMPS-K')
	set @LucrCuDiurneNeimpoz=dbo.iauParL('PS','DIUNEIMP')
--	parametrii lunari	
	set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @pCASIndiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @SalMin=dbo.iauParLN(@dataSus,'PS','S-MIN-BR')
	set @SalMediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	set @Data1_an=dbo.boy(@dataJos)

	if object_id('tempdb..#DateAsigurati') is not null drop table #DateAsigurati
	if object_id('tempdb..#pontajGrpM') is not null drop table #pontajGrpM
	if object_id('tempdb..#pontajMarca') is not null drop table #pontajMarca
	if object_id('tempdb..#sindicat') is not null drop table #sindicat
	if object_id('tempdb..#ticheteImpozitate') is not null drop table #ticheteImpozitate

--	pun tichetele de insumat la venit brut in tabela temporara. Functioneaza mult mai rapid.
	select data, marca, valoare_tichete into #ticheteImpozitate from fDecl205Tichete (@dataJos, @dataSus)

--	pun valoarea sindicatului deductibil in tabela temporara. Functioneaza mult mai rapid.		
	select data, marca, SindicatDeductibil into #sindicat from fSindicatDeductibil (@dataJos, @dataSus) 
	
	create table #DateAsigurati
	(Data datetime, TagAsigurat char(20), Marca char(6), Nume char(50), CNP char(13), Tip_asigurat int, Pensionar int, Tip_contract char(2), Tip_functie char(1), 
		Data_angajarii datetime, Total_zile int, Zile_CN int, Zile_CD int, Zile_CS int, TV decimal (10), TVN decimal (10), TVD decimal (10), TVS decimal (10), 
		Ore_norma int, IND_CS int, NRZ_CFP int, Norma_luna int,
		Zile_lucrate int, Ore_lucrate int, Zile_suspendate int, Ore_suspendate int, OreSST int, ZileSST int, BazaST int, 
		Venit_total decimal(10), Venit_fara_CM decimal(10), Baza_CAS decimal(10), CAS_individual decimal (10), 
		Baza_somaj decimal(10), Somaj_individual decimal(7), Baza_CASS decimal(10), CASS_individual decimal(7), Baza_FG decimal(10), Regim_de_lucru float, 
		Contributii_sociale decimal(10), Valoare_tichete decimal(10), nr_persintr int, Deduceri_personale decimal(10), Alte_deduceri decimal(10), 
		Baza_impozit decimal(10), Impozit decimal(10), Salar_net decimal(10), Tip_personal char(1))
	create unique index [Data_Marca_Locm] ON #DateAsigurati (Data, Marca, TagAsigurat, CNP)

--	tabela temporara pt. datele centralizate pe grupe de munca catre BASS 
	select dbo.eom(a.data) as Data, a.Marca, a.Loc_de_munca, a.Grupa_de_munca, 
	sum(round((a.ore_regie+(case when @Somesana=1 then 0 else a.ore_acord end)+a.ore_concediu_de_odihna+a.ore_obligatii_cetatenesti+
	(case when @Pasmatex=0 then (case when not(@IT1SuspContr=1 and @ProcIT1=0) then a.ore_intrerupere_tehnologica else 0 end)
		+(case when @Elite=0 and @STOUG28=0 and not(@IT2SuspContr=1 and @ProcIT2=0) then a.ore else 0 end) else 0 end)
		-@ScadOSRN*(a.ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else a.ore_suplimentare_2 end)+a.ore_suplimentare_3+a.ore_suplimentare_4)
		-@ScadO100RN*(a.ore_spor_100)+(case when @Colas=1 then a.spor_cond_8 else 0 end))/a.regim_de_lucru,2)
		+(case when @Salubris=1 then round((a.ore_suplimentare_1+a.ore_suplimentare_2-a.ore_suplimentare_3)/a.regim_de_lucru,2) else 0 end)) as Zile_asigurate, 
	sum(a.ore_concediu_medical/a.regim_de_lucru) as Zile_CM
	into #pontajGrpM
	from pontaj a
		left outer join istpers i on i.Data=@dataSus and i.Marca=a.Marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where a.data between @dataJos and @dataSus and (@Marca is null or a.Marca=@Marca) and i.grupa_de_munca<>'O' 
		and (@lm='' or i.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and (@SirMarci is null or charindex(','+rtrim(ltrim(a.marca))+',',@SirMarci)>0)
		and (@lista_lm=0 or lu.cod is not null) 
	group by dbo.eom(a.data), a.Marca, a.Loc_de_munca, a.grupa_de_munca

	create unique index [Data_Marca_Locm] ON #pontajGrpM (Data, Marca, Loc_de_munca, Grupa_de_munca)

--	tabela temporara pt. datele de somaj centralizate pe marca
	select dbo.eom(a.Data) as Data, a.marca, (case when max(a.Regim_de_lucru)=0 then 8 else max(a.Regim_de_lucru) end) as RegimLucru, 
	round((sum(round((a.ore_regie+(case when @Somesana=1 then 0 else a.ore_acord end)+a.ore_concediu_de_odihna+a.ore_obligatii_cetatenesti
		+(case when @Pasmatex=0 then (case when @IT1SuspContr=0 then a.ore_intrerupere_tehnologica else 0 end)
			+(case when @Elite=0 and @STOUG28=0 and @IT2SuspContr=0 then a.ore else 0 end) else 0 end)
		+(case when @Colas=1 or @denIntrTehn3<>'' and @IT3SuspContr=0 then a.spor_cond_8 else 0 end)
		-@ScadOSRN*(a.ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else a.ore_suplimentare_2 end)+a.ore_suplimentare_3+a.ore_suplimentare_4)
		-@ScadO100RN*(a.ore_spor_100) +@Salubris*(ore_suplimentare_1+ore_suplimentare_2-ore_suplimentare_3))/a.regim_de_lucru,2,3))),0)
		+max(isnull(cm.ZileCM_angajator,0)) as Zile_lucrate, 
	(sum(round((a.ore_regie+(case when @Somesana=1 then 0 else a.ore_acord end)+a.ore_concediu_de_odihna+a.ore_obligatii_cetatenesti
		+(case when @Pasmatex=0 then (case when @IT1SuspContr=0 then a.ore_intrerupere_tehnologica else 0 end)
			+(case when @Elite=0 and @STOUG28=0 and @IT2SuspContr=0 then a.ore else 0 end) else 0 end)
		+(case when @Colas=1 or @denIntrTehn3<>'' and @IT3SuspContr=0 then a.spor_cond_8 else 0 end)
		-@ScadOSRN*(a.ore_suplimentare_1+(case when @ORegieFaraOS2=1 then 0 else a.ore_suplimentare_2 end)+a.ore_suplimentare_3+a.ore_suplimentare_4)-@ScadO100RN*(a.ore_spor_100)
		+@Salubris*(ore_suplimentare_1+ore_suplimentare_2-ore_suplimentare_3)),3,3))) 
		+max(isnull(cm.ZileCM_angajator,0))*max(a.regim_de_lucru) as Ore_lucrate, 
	(sum(round((a.ore_concediu_fara_salar+a.ore_nemotivate+a.ore_invoiri+(case when @IT1SuspContr=1 then a.Ore_intrerupere_tehnologica else 0 end)
		+(case when @STOUG28=1 or @IT2SuspContr=1 then a.ore else 0 end)+(case when @denIntrTehn3<>'' and @IT3SuspContr=1 then a.Spor_cond_8 else 0 end))
			/(case when a.regim_de_lucru=0 then 8 else a.regim_de_lucru end),2)))
		+max(isnull(cm.ZileCM_fonduri,0)) as Zile_suspendate, 
	(sum(round((a.ore_concediu_fara_salar+a.ore_nemotivate+a.ore_invoiri+(case when @IT1SuspContr=1 then a.Ore_intrerupere_tehnologica else 0 end)
		+(case when @STOUG28=1 or @IT2SuspContr=1 then a.ore else 0 end)+(case when @denIntrTehn3<>'' and @IT3SuspContr=1 then a.Spor_cond_8 else 0 end)),3)))+
		max(isnull(cm.ZileCM_fonduri,0))*max(a.regim_de_lucru) as Ore_suspendate, 
	(case when @STOUG28=1 then sum(a.ore) else 0 end) as OreSST, 
	(case when @STOUG28=1 then sum(a.ore/a.regim_de_lucru) else 0 end) as ZileSST, 
	(case when @STOUG28=1 then round(@SalMin*sum(a.ore/a.regim_de_lucru)/(@OreLuna/8),0) else 0 end) as SB
	into #pontajMarca
	from pontaj a
		left outer join #net n on n.data=dbo.eom(a.Data) and a.marca=n.marca
		left outer join Personal p on a.marca=p.marca
		left outer join istPers i on i.data=n.data and a.marca=i.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
		left outer join (select data, marca, sum(Zile_cu_reducere*(case when tip_diagnostic='10' then 0.25 else 1 end)) as ZileCM_angajator, 
			sum((Zile_lucratoare-Zile_cu_reducere)*(case when tip_diagnostic='10' then 0.25 else 1 end)) as ZileCM_fonduri 
			from conmed 
			where Data_inceput between @dataJos and @dataSus group by data, marca) cm on cm.Data=n.data and cm.Marca=a.Marca
		left outer join #TagAsigurat ta on ta.data=n.data and ta.marca=a.marca
	where a.data between @dataJos and @dataSus and (@Marca is null or a.marca=@Marca)  
		and (@Lm='' or i.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and (@SirMarci is null or charindex(','+rtrim(ltrim(a.marca))+',',@SirMarci)>0)
		and (@TagAsigurat is null or @TagAsigurat like rtrim(ta.TagAsigurat)+'%')
		and (@lista_lm=0 or lu.cod is not null) 
	group by dbo.eom(a.Data), a.Marca
	order by dbo.eom(a.Data), a.Marca

	create unique index [Data_Marca] ON #pontajMarca (Data, Marca)

	insert into #DateAsigurati
	select a.Data, ta.TagAsigurat, a.Marca as Marca, a.Nume as Nume, p.cod_numeric_personal as CNP, 
	ta.Tip_asigurat, ta.Pensionar, ta.Tip_contract, ta.Tip_functie, p.Data_angajarii_in_unitate, 
	isnull((select round(sum(b.Zile_asigurate+b.Zile_CM),0) from #pontajGrpM b where b.data=a.Data and b.marca=a.marca),0) as TT, 
	isnull((select round(sum(b.Zile_asigurate),0) from #pontajGrpM b where b.data=a.Data and b.Grupa_de_munca='N' and b.marca=a.marca),0) as NN,
	isnull((select round(sum(b.Zile_asigurate),0) from #pontajGrpM b where b.data=a.Data and b.Grupa_de_munca='D' and b.marca=a.marca),0) as DD,
	isnull((select round(sum(b.Zile_asigurate),0) from #pontajGrpM b where b.data=a.Data and b.Grupa_de_munca='S' and b.marca=a.marca),0) as SS,
--	total venit
	isnull((select sum(c.venit_cond_normale+c.venit_cond_deosebite+c.venit_cond_speciale-@NuCAS_H*c.suma_impozabila
		-(case when i.grupa_de_munca<>'P' then @ASSImpS_K*c.cons_admin else 0 end)-(c.ind_c_medical_unitate+c.ind_c_medical_cas+c.CMCAS+c.CMunitate+c.spor_cond_9)
		-@vSTOUG28*round(c.Ind_invoiri,0))-max(isnull(pf1.Suma_corectie,0)) 
	from #brut c
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'T-', @Marca, @Lm, 1) pf1 on pf1.Data=c.Data and pf1.Marca=c.Marca and pf1.Loc_de_munca=c.Loc_de_munca
		, istpers i 
	where c.data=@dataSus and c.marca=a.marca and c.data=i.data and c.marca=i.marca),0) as TV, 
--	total venit pe conditii normale de munca
	isnull((select sum(c.venit_cond_normale) from #brut c where c.data=@dataSus and c.marca=a.marca),0)
		-isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate-@NuCAS_H*g.suma_impozabila
			+(case when i.grupa_de_munca<>'P' then @ASSImpS_K*g.cons_admin else 0 end)+g.spor_cond_9+@vSTOUG28*round(g.Ind_invoiri,0))
		+max(isnull(pf1.Suma_corectie,0))
	from #brut g
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'T-', @Marca, @Lm, 1) pf1 on pf1.Data=g.Data and pf1.Marca=g.Marca and pf1.Loc_de_munca=g.Loc_de_munca
		left outer join #pontajGrpM f on g.data=f.data and g.marca=f.marca and g.loc_de_munca = f.loc_de_munca and f.grupa_de_munca='N'
		left outer join istpers i on g.data=i.data and g.marca=i.marca
	where g.data=@dataSus and g.marca=a.marca and f.grupa_de_munca='N'),0) 
	- isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate+g.spor_cond_9-@NuCAS_H*g.suma_impozabila+@ASSImpS_K*g.cons_admin+
		@vSTOUG28*round(g.Ind_invoiri,0)) from #brut g where g.data=@dataSus and g.marca=a.marca and a.grupa_de_munca='N' 
			and g.loc_de_munca not in (select loc_de_munca from pontaj t where g.marca=t.marca and t.data between @dataJos and @dataSus)),0) as TVN, 
--	total venit pe conditii deosebite de munca
	isnull((select sum(c.venit_cond_deosebite) from #brut c where c.data=@dataSus and c.marca=a.marca),0)
		-isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate-@NuCAS_H*g.suma_impozabila+@ASSImpS_K*g.cons_admin
			+g.spor_cond_9+@vSTOUG28*round(g.Ind_invoiri,0))+max(isnull(pf1.Suma_corectie,0))
	from #brut g 
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'T-', @Marca, @Lm, 1) pf1 on pf1.Data=g.Data and pf1.Marca=g.Marca and pf1.Loc_de_munca=g.Loc_de_munca
		left outer join #pontajGrpM f on g.data=f.data and g.marca=f.marca and g.loc_de_munca=f.loc_de_munca and f.grupa_de_munca='D' 
	where g.data=@dataSus and g.marca=a.marca and f.grupa_de_munca='D'),0) 
		- isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate-@NuCAS_H*g.suma_impozabila +@ASSImpS_K*g.cons_admin+g.spor_cond_9
			+@vSTOUG28*round(g.Ind_invoiri,0)) from #brut g where g.data=@dataSus and g.marca=a.marca and a.grupa_de_munca='D' 
				and g.loc_de_munca not in (select loc_de_munca from pontaj t where g.marca=t.marca and t.data between @dataJos and @dataSus)),0) as TVD, 
--	total venit pe conditii speciale de munca
	isnull((select sum(c.venit_cond_speciale) from #brut c where c.data=@dataSus and c.marca=a.marca),0) 
		- isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate-@NuCAS_H*g.suma_impozabila+@ASSImpS_K*g.cons_admin+g.spor_cond_9
		+@vSTOUG28*round(g.Ind_invoiri,0))+max(isnull(pf.Suma_corectie,0))
	from #brut g 
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'T-', @Marca, @Lm, 1) pf on pf.Data=g.Data and pf.Marca=g.Marca and pf.Loc_de_munca=g.Loc_de_munca
		left outer join #pontajGrpM f on g.data=f.data and g.marca=f.marca and g.loc_de_munca=f.loc_de_munca and f.grupa_de_munca='S'
	where g.data=@dataSus and g.marca=a.marca and f.grupa_de_munca='S'),0) 
		- isnull((select sum(g.ind_c_medical_unitate+g.ind_c_medical_cas+g.CMCAS+g.CMunitate-@NuCAS_H*g.suma_impozabila+@ASSImpS_K*g.cons_admin+g.spor_cond_9
		+@vSTOUG28*round(g.Ind_invoiri,0)) from #brut g where g.data=@dataSus and g.marca=a.marca and a.grupa_de_munca='S' 
			and g.loc_de_munca not in (select loc_de_munca from pontaj t where g.marca=t.marca and t.data between @dataJos and @dataSus)),0) as TVS, 
	(case when DATEDIFF(day,@dataJos,DateADD(year,18,p.Data_nasterii))>0 and year(p.Data_nasterii)>1901 and a.Grupa_de_munca in ('N','D','S') then 6
		when a.Grupa_de_munca in ('C','O') then 8 else isnull((select (case when max(d.spor_cond_10)>8 or max(d.spor_cond_10)=0 or a.grupa_de_munca='P' then 8 
			else max(d.spor_cond_10) end) from #brut d where d.data=@dataSus and d.marca=a.marca),8) end) as NORMA, 
	(case when a.grupa_de_munca='S' then isnull((select top 1 convert(int,val_inf) 
		from extinfop x where x.marca=a.marca and x.cod_inf='INDCS' and x.data_inf<=@dataSus order by x.data_inf desc),0) else 0 end) as IND_CS, 0 as NRZ_CFP, 
	round((case when isnull(pm.RegimLucru,0)=0 then 8 else isnull(pm.RegimLucru,0) end)
		*(case when a.Data<@dataSus then (case when dbo.iauParLN(a.Data,'PS','ORE_LUNA')=0 then dbo.Zile_lucratoare(dbo.bom(a.Data),a.Data)*8 
			else dbo.iauParLN(a.Data,'PS','ORE_LUNA') end) else @OreLuna end)/8,0) as Norma_luna, 
	isnull(pm.Zile_lucrate,0) as Zile_lucrate, isnull(pm.Ore_lucrate,0) as Ore_lucrate, 
	isnull(pm.Zile_suspendate,0) as Zile_suspendate, isnull(pm.Ore_suspendate,0) as Ore_suspendate, 
	isnull(pm.OreSST,0) as OreSST, isnull(pm.ZileSST,0) as ZileSST, isnull(pm.SB,0) as BazaST, 
	isnull(bm.Venit_total,0), isnull(bm.Venit_total-(bm.ind_c_medical_unitate+bm.ind_c_medical_cas+bm.spor_cond_9),0) as Venit_fara_CM, 
	isnull(n.Baza_CAS,0) as Baza_CAS, isnull(n.pensie_suplimentara_3,0) - isnull((select round(convert(float,0.35*@SalMediu)*sum(m.zile_lucratoare)/max(m.zile_lucratoare_in_luna)*@pCASIndiv/100,0) 
		from conmed m where year(m.data)>=2006 and m.data=@DataSus and m.data_inceput<@dataJos and m.marca=a.marca 
		and (m.tip_diagnostic not in ('2-','3-','4-','0-') and (m.tip_diagnostic<>'10' and m.tip_diagnostic<>'11' or m.suma<>1))),0) as CAS_individual, 
	isnull((case when n.Somaj_1<>0 or n.Asig_sanatate_din_cas<>0 and p.Somaj_1<>0 then n.Asig_sanatate_din_cas else 0 end),0) as Baza_somaj, isnull(n.Somaj_1,0) as Somaj_1, 
	isnull((case when n.Asig_sanatate_din_net<>0 or n1.Asig_sanatate_din_net<>0 and p.As_sanatate<>0  
		then (case when n1.Asig_sanatate_din_net<>0 and p.As_sanatate<>0 
			then n1.Asig_sanatate_din_net 
			else bm.venit_total-(bm.ind_c_medical_cas+bm.spor_cond_9+bm.CMCAS)-1*(bm.ind_c_medical_unitate+bm.CMunitate)-@NuCASS_H*bm.suma_impozabila
				-(case when @STOUG28=1 then bm.Ind_invoiri else 0 end) end) 
		else 0 end),0) as Baza_CASS, isnull(n.Asig_sanatate_din_net,0), 
	isnull((case when @InstPubl=1 or n1.somaj_5=0 then 0 else (case when YEAR(a.Data)<=2011 or n1.CM_incasat=0 
		then isnull(n.Asig_sanatate_din_CAS,0) else n1.CM_incasat end) end),0) as Baza_FG, ta.Regim_de_lucru, 
	isnull(n.Pensie_suplimentara_3+n.Somaj_1+n.Asig_sanatate_din_net,0) as Contributii_sociale, isnull(t.Valoare_tichete,0) as Valoare_tichete, 
	isnull((select count(1) from persintr pe where pe.Marca=a.Marca and pe.Data=@dataSus and pe.Coef_ded<>0),0) as nr_persintr, 
	isnull(n.Ded_baza,0), isnull(n1.Ded_baza,0)+isnull(sd.SindicatDeductibil,0) as alte_deduceri, 
-->	Corect ar fi zic eu ca Baza impozit sa fie egala cu baza la care s-a aplicat impozitarea. 
-->	Instructiunile de la D112 nu tin cont de sumele neimpozabile (indemnizatii sarcina si lahuzie, ingrjire copil bolnav, avantaje materiale)
	(case when 1=0 then isnull(n.Venit_baza,0) 
		else (case	when isnull(bm.Venit_total,0)-isnull(n.Pensie_suplimentara_3+n.Somaj_1+n.Asig_sanatate_din_net,0)-isnull(n.Ded_baza,0)-isnull(n1.Ded_baza,0)-isnull(sd.SindicatDeductibil,0)
							+isnull(t.Valoare_tichete,0)+isnull(q.Suma_corectie,0)>0 
					then isnull(bm.Venit_total,0)-isnull(n.Pensie_suplimentara_3+n.Somaj_1+n.Asig_sanatate_din_net,0)-isnull(n.Ded_baza,0)-isnull(n1.Ded_baza,0)-isnull(sd.SindicatDeductibil,0)
							+isnull(t.Valoare_tichete,0)+isnull(q.Suma_corectie,0) 
					else 0 end) end) as baza_impozit, isnull(n.impozit+n.Diferenta_impozit,0), 
	isnull(n.venit_net,0)+isnull(t.Valoare_tichete,0)-(case when @NuASS_N=1 and isnull(q.Suma_corectie,0)=0 then isnull(n.Suma_neimpozabila,0) else 0 end)
		-(case when @LucrCuDiurneNeimpoz=1 then isnull(dn.Suma_corectie,0) else 0 end) as Salar_net, 'S' Tip_personal
	from #istpers a 
		left outer join #TagAsigurat ta on a.data=ta.data and a.marca=ta.marca
		left outer join personal p on a.marca=p.marca 
		left outer join #net n on n.data=a.data and n.marca=a.marca
		left outer join #net n1 on n1.data=dbo.bom(a.data) and n1.marca=a.marca
		left outer join #brutMarca bm on a.data=bm.data and a.marca=bm.marca
		left outer join #pontajMarca pm on a.data=pm.data and a.marca=pm.marca 
		left outer join #sindicat sd on a.data=sd.data and a.marca=sd.marca 
		left outer join #ticheteImpozitate t on a.data=t.data and a.marca=t.marca 
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Q-', @marca, @Lm, 0) q on q.Data=a.Data and q.Marca=a.Marca 
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'W-', @marca, @Lm, 0) dn on dn.Data=a.Data and dn.Marca=a.Marca 
	where a.data=@dataSus and (@Marca is null or a.Marca=@Marca) --and (a.grupa_de_munca<>'O' or a.tip_colab in ('DAC','CCC','ECT'))
		and (@Lm='' or a.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and (@SirMarci is null or charindex(','+rtrim(ltrim(a.marca))+',',@SirMarci)>0)
		and (@TagAsigurat is null or @TagAsigurat like rtrim(ta.TagAsigurat)+'%')
	order by Marca

	update #DateAsigurati set TV=(case when TV<0 then 0 else TV end), 
		TVN=(case when TVN<0 then 0 else TVN end), TVD=(case when TVD<0 then 0 else TVD end), 
		TVS=(case when TVS<0 then 0 else TVS end)
	where (TVN<0 or TVD<0 or TVS<0) and (@Marca is null or Marca=@Marca) 

	insert into #DateAsigurati
	select dbo.EOM(sz.data), 'asiguratC', sz.Marca as Marca, max(z.Nume) as Nume, max(z.cod_numeric_personal) as CNP, 
	18 as Tip_asigurat, 0, 'N' as Tip_contract, '3' as Tip_functie, max(z.Data_angajarii), 
	0 as TT, 0 as NN, 0 as DD, 0 as SS, 0 as TV, 0 as TVN, 0 as TVD, 0 as TVS, 8 as NORMA, 0 as IND_CS, 0 as NRZ_CFP, @OreLuna as Norma_luna, 
	0 as Zile_lucrate, 0 as Ore_lucrate, 0 as Zile_suspendate, 0 as Ore_suspendate, 0 as OreSST, 0 as ZileSST, 0 as BazaST, 
	/*sum(isnull(sz.Venit_total,0))*/0 as Venit_total, 0 as Venit_fara_CM, 0 as Baza_CAS, 0 as CAS_individual, 0 as Baza_somaj, 0 as Somaj_1, 
	0 as Baza_CASS, 0 as CASS, 0 as Baza_FG, 8 as Regim_de_lucru, 0 as Contributii_sociale, 0 as Valoare_tichete, 0 as nr_persintr, 0 as DedBaza, 0 as alte_deduceri, 
	sum(isnull(sz.Venit_total,0)) as baza_impozit, sum(isnull(sz.Impozit,0)) as Impozit, 
	sum(isnull(sz.Venit_total,0))-sum(isnull(sz.Impozit,0)) as Salar_net, 'Z' Tip_personal
	from #SalariiZilieri sz 
		left outer join #zilieri z on z.marca=sz.marca 
	group by dbo.EOM(sz.data), sz.marca
	order by sz.Marca

	select Data, TagAsigurat, Marca, Nume, CNP, Tip_asigurat, Pensionar, Tip_contract, Tip_functie, Data_angajarii, 
		Total_zile, Zile_CN, Zile_CD, Zile_CS, TV, TVN, TVD, TVS, Ore_norma, IND_CS, NRZ_CFP, Norma_luna,
		Zile_lucrate, Ore_lucrate, Zile_suspendate, Ore_suspendate, OreSST, ZileSST, BazaST, 
		Venit_total, Venit_fara_CM, Baza_CAS, CAS_individual, Baza_somaj, Somaj_individual, Baza_CASS, CASS_individual, Baza_FG, Regim_de_lucru, 
		Contributii_sociale, Valoare_tichete, nr_persintr, Deduceri_personale, Alte_deduceri, Baza_impozit, Impozit, Salar_net, Tip_personal
	from #DateAsigurati	

	return
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura Declaratia112Asigurati (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec Declaratia112Asigurati '01/01/2014', '01/31/2014', null, '', 0, null, ''
*/
