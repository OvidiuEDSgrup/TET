--***
/**	fluturasi detaliere retineri - pt. completare tabela tmpfluturi */
Create procedure fluturasi_detaliere_retineri 
	@Host_ID char(10), @dataJos datetime, @dataSus datetime, @Ordonare char(100), 
	@Filtru_marci int, @Marca_jos char(6), @Marca_sus char(6), @Filtru_locm int, @Locm_jos char(9), @Locm_sus char(9), 
	@Fitru_functie int, @Functia char(6), @lGrupa_de_munca int, @cGrupa_de_munca char(1), @lGrupa_de_munca_exceptata int, 
	@Salarii_conducere int, @Lista_conducere char(1), @Filtru_mandatar int, @Mandatar char(6), @Rest_plata_poz int,  
	@Un_tip_stat int, @Tip_stat char(200), @Un_sir_de_marci int, @Sir_marci char(200), @Un_card int, @Card char(30),@Det_comp_saln int, 
	@ltip_salarizare int, @ctip_sal char(1) 
as
Begin
	declare @userASiS char(10), @Drept_conducere int, @Colas int, @Afisare_ore_delegatie int, @den_intr3 char(30)
	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @userASiS=dbo.fIaUtilizator(null)
	Exec Luare_date_par 'PS','DREPTCOND',@Drept_conducere output,0,0
	Exec Luare_date_par 'PS','FLDOREDLG',@Afisare_ore_delegatie output,0,0
	Exec Luare_date_par 'PS','PROC3INT',0,0,@den_intr3 output
	Exec Luare_date_par 'SP','COLAS',@Colas output,0,0
	
	delete from tmpfluturi where host_ID=@Host_ID
	delete from flutur where HostID=@Host_ID

	/*if exists(select * from sysobjects where name='tmpfluturi') drop table tmpfluturi */
	insert into tmpfluturi(Host_ID,Data,Marca,Loc_de_munca,Loc_munca_pt_stat_de_plata,Total_ore_lucrate,Ore_lucrate__regie,
	Realizat__regie,Ore_lucrate_acord,Realizat_acord,Ore_suplimentare_1,Indemnizatie_ore_supl_1,Ore_suplimentare_2,
	Indemnizatie_ore_supl_2,Ore_suplimentare_3,Indemnizatie_ore_supl_3,Ore_suplimentare_4,Indemnizatie_ore_supl_4,
	Ore_spor_100,Indemnizatie_ore_spor_100,Ore_de_noapte,Ind_ore_de_noapte,Ore_lucrate_regim_normal,Ind_regim_normal,
	Ore_intrerupere_tehnologica,Ind_intrerupere_tehnologica,Ore_obligatii_cetatenesti,Ind_obligatii_cetatenesti,Ore_concediu_fara_salar,
	Ind_concediu_fara_salar,Ore_concediu_de_odihna,Ind_concediu_de_odihna,Ore_concediu_medical,Ind_c_medical_unitate,Ind_c_medical_CAS,
	Ore_invoiri,Ind_invoiri,Ore_nemotivate,Ind_nemotivate,Salar_categoria_lucrarii,Ore_realizate_acord,CMCAS,CMunitate,
	CO,Restituiri,Diminuari,Suma_impozabila,Premiu,Diurna,Cons_admin,Sp_salar_realizat,Suma_imp_separat,Spor_vechime,
	Spor_de_noapte,Spor_sistematic_peste_program,Spor_de_functie_suplimentara,Spor_specific,Spor_cond_1,Spor_cond_2,Spor_cond_3,
	Spor_cond_4,Spor_cond_5,Spor_cond_6,Compensatie,VENIT_TOTAL,Salar_orar,Venit_cond_normale,Venit_cond_deosebite,Venit_cond_speciale,
	Spor_cond_7,Spor_cond_8,Spor_cond_9,Spor_cond_10,Cod_functie,Nume,Ordonare,Ore_sistematic_peste_program,Ore__cond_1,Ore__cond_2,
	Ore__cond_3,Ore__cond_4,Ore__cond_5,Ore__cond_6,Ore_intr_tehn_2,Ore_intr_tehn_3,Ore_delegatie,Realizat_delegatie)

	select @Host_ID as Host_ID,a.data,a.marca,a.loc_de_munca,a.loc_munca_pt_stat_de_plata,a.total_ore_lucrate,a.ore_lucrate__regie,
	a.realizat__regie,a.ore_lucrate_acord,a.realizat_acord,a.ore_suplimentare_1,a.indemnizatie_ore_supl_1,a.ore_suplimentare_2,
	a.indemnizatie_ore_supl_2,a.ore_suplimentare_3,a.indemnizatie_ore_supl_3,a.ore_suplimentare_4,a.indemnizatie_ore_supl_4,
	a.ore_spor_100,a.indemnizatie_ore_spor_100,a.ore_de_noapte,a.ind_ore_de_noapte,a.ore_lucrate_regim_normal,a.ind_regim_normal,
	a.ore_intrerupere_tehnologica-isnull(Ore_intr_tehn_2,0), 
	a.ind_intrerupere_tehnologica,a.ore_obligatii_cetatenesti,a.ind_obligatii_cetatenesti,a.ore_concediu_fara_salar, 
	a.ind_concediu_fara_salar,a.ore_concediu_de_odihna,a.ind_concediu_de_odihna,a.ore_concediu_medical,a.ind_c_medical_unitate,a.ind_c_medical_cas,
	a.ore_invoiri, a.ind_invoiri, a.ore_nemotivate, a.ind_nemotivate,a.salar_categoria_lucrarii, isnull(po.ore_realizate_acord,0), 
	a.cmcas, a.cmunitate,a.co,a.restituiri,a.diminuari,a.suma_impozabila,a.premiu,a.diurna,a.cons_admin,a.sp_salar_realizat,a.suma_imp_separat,a.spor_vechime,
	a.spor_de_noapte,a.spor_sistematic_peste_program,a.spor_de_functie_suplimentara,a.spor_specific,a.spor_cond_1,a.spor_cond_2,a.spor_cond_3,
	a.spor_cond_4,a.spor_cond_5,a.spor_cond_6,a.compensatie,a.venit_total,a.salar_orar,a.venit_cond_normale,a.venit_cond_deosebite,a.venit_cond_speciale,
	a.spor_cond_7,a.spor_cond_8,a.spor_cond_9,a.spor_cond_10,b.cod_functie,b.nume, 
	(case when @Ordonare='Nume' then b.Nume+a.Marca when @Ordonare='Loc de munca; Nume' then c.Loc_de_munca+b.Nume+a.Marca 
		else c.Loc_de_munca+b.Cod_functie+a.Marca end)+a.Loc_de_munca as ordonare,
	isnull(po.ore_sistematic_peste_program,0), isnull(po.ore__cond_1,0), isnull(po.ore__cond_2,0), isnull(po.ore__cond_3,0), 
	isnull(po.ore__cond_4,0), isnull(po.ore__cond_5,0), isnull(po.ore_donare_sange,0), isnull(po.Ore_intr_tehn_2,0), 
	(case when @Colas=1 or @den_intr3<>'' then isnull(po.Ore_intr_tehn_3,0) else 0 end), isnull(po.Ore_delegatie,0), round(isnull(po.Ore_delegatie*a.Salar_orar,0),0)
	from brut a
		left outer join (select dbo.EOM(j.Data) as Data, Marca, Loc_de_munca, sum(ore_realizate_acord) as ore_realizate_acord, 
				sum(ore_sistematic_peste_program) as ore_sistematic_peste_program, sum(ore__cond_1) as ore__cond_1, sum(Ore__cond_2) as ore__cond_2, 
				sum(Ore__cond_3) as ore__cond_3, sum(Ore__cond_4) as ore__cond_4, sum(ore__cond_5) as ore__cond_5, sum(ore_donare_sange) as ore_donare_sange, 
				SUM(ore) as Ore_intr_tehn_2, sum(spor_cond_8) as Ore_intr_tehn_3, (case when @Afisare_ore_delegatie=1 then sum(Spor_cond_10) else 0 end) as Ore_delegatie
		from pontaj j where j.data between @dataJos and @dataSus group by dbo.EOM(j.Data),Marca,Loc_de_munca) po on po.Data=a.Data and po.Marca=a.Marca and po.Loc_de_munca=a.Loc_de_munca
		, personal b, net c 
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=c.Loc_de_munca
		, infopers d, istpers i
	where a.marca=b.marca and a.data=c.data and a.marca=c.marca and a.marca=d.marca and a.Data=i.Data and a.Marca=i.Marca
		and a.data between @dataJos and @dataSus and (@Filtru_marci=0 or a.marca between @Marca_jos and @Marca_sus) 
		and (@Filtru_locm=0 or c.loc_de_munca between @Locm_jos and @Locm_sus) and (@Fitru_functie=0 or i.cod_functie=@Functia) 
		and (@lGrupa_de_munca=0 or (@lGrupa_de_munca_exceptata=0 and i.grupa_de_munca=@cGrupa_de_munca or @lGrupa_de_munca_exceptata=1 and i.grupa_de_munca<>@cGrupa_de_munca)) 
		and (@Drept_conducere=0 or (@Salarii_conducere=1 and (@Lista_conducere='T' or @Lista_conducere='C' and b.pensie_suplimentara=1 
			or @Lista_conducere='S' and b.pensie_suplimentara<>1)) or (@Salarii_conducere=0 and b.pensie_suplimentara<>1)) 
		and (@Filtru_mandatar=0 or c.loc_de_munca in (select loc_munca from mandatar where mandatar=@Mandatar)) 
		and (@Rest_plata_poz=0 or c.rest_de_plata>0) and (@Un_tip_stat=0 or d.religia=@Tip_stat) 
		and (@Un_sir_de_marci=0 or charindex(','+rtrim(ltrim(a.marca))+',',@Sir_marci)>0) and (@Un_card=0 or b.banca=@Card) 
		and (@ltip_salarizare=0 or @ctip_sal='T' and i.Tip_salarizare between '1' and '2' or @ctip_sal='M' and i.Tip_salarizare between '3' and '7') 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)

	if object_id('tempdb..#impozitIpotetic') is not null drop table #impozitIpotetic
	if object_id('tempdb..#contor_marca') is not null drop table #contor_marca
	create table #impozitIpotetic (data datetime, marca varchar(6), ImpozitIpotetic varchar(100))
-->	selectez din extinfop, pozitia pentru salariatii care au impozit ipotetic (HG84/2013) valabila la data declaratiei. Acest impozit ipotetic va fi afisat cu denumirea codului de informatie definit.
	insert into #impozitIpotetic
	select data, marca, ImpozitIpotetic 
	from dbo.fSalariatiCuImpozitIpotetic (@dataJos, @dataSus, @Locm_jos, @Marca_jos)

	create table #contor_marca (contor_marca int)
	-- apeleaza procedura fluturasi_brut pt. scriere fluturasi pe verticala pe 1/2/3 coloane 
	exec fluturasi_brut @dataJos, @dataSus, @Host_ID, @Ordonare, @Det_comp_saln

--	apelare procedura specifica (pt. inceput se va folosi la Remarul - sesizarea 235055)
	if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'fluturasi_detaliere_retineriSP') and type='P')
		exec fluturasi_detaliere_retineriSP

	if object_id('tempdb..#impozitIpotetic') is not null drop table #impozitIpotetic
	if object_id('tempdb..#contor_marca') is not null drop table #contor_marca
End
