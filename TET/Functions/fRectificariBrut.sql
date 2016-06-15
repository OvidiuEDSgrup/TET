/*
	functia returneaza diferentele pe tabela brut rezultate dintr-un calcul de lichidare pe o luna inchisa in raport cu calculul initial (cand s-a depus D112)
	@locapelare='LR' - > apelare procedura din luna rectificata (inchisa dpdv. contabil) - cea pe care se declara diferentele in D112
	@locapelare='LC' - > apelare procedura din luna curenta - cea pe care se inregistreaza contabil diferentele
*/	
Create function fRectificariBrut (@parXML xml)
returns @rectificaribrut table 
	(Data datetime, Marca char(6), Loc_de_munca char(9), Loc_munca_pt_stat_de_plata bit, Total_ore_lucrate smallint, Ore_lucrate__regie smallint, Realizat__regie float,
	Ore_lucrate_acord smallint, Realizat_acord float, Ore_suplimentare_1 smallint, Indemnizatie_ore_supl_1 float, Ore_suplimentare_2 smallint, Indemnizatie_ore_supl_2 float,
	Ore_suplimentare_3 smallint, Indemnizatie_ore_supl_3 float, Ore_suplimentare_4 smallint, Indemnizatie_ore_supl_4 float, 
	Ore_spor_100 smallint, Indemnizatie_ore_spor_100 float, Ore_de_noapte smallint, Ind_ore_de_noapte float, Ore_lucrate_regim_normal smallint, Ind_regim_normal float,
	Ore_intrerupere_tehnologica smallint, Ind_intrerupere_tehnologica float, Ore_obligatii_cetatenesti smallint, Ind_obligatii_cetatenesti float, 
	Ore_concediu_fara_salar smallint, Ind_concediu_fara_salar float, Ore_concediu_de_odihna smallint, Ind_concediu_de_odihna float, Ore_concediu_medical smallint,
	Ind_c_medical_unitate float, Ind_c_medical_CAS float, Ore_invoiri smallint, Ind_invoiri float, Ore_nemotivate smallint, Ind_nemotivate float, Salar_categoria_lucrarii float, 
	CMCAS float, CMunitate float, CO float, Restituiri float, Diminuari float, Suma_impozabila float, Premiu float, Diurna float, Cons_admin float, Sp_salar_realizat float,
	Suma_imp_separat float, Spor_vechime float, Spor_de_noapte float, Spor_sistematic_peste_program float, Spor_de_functie_suplimentara float, 
	Spor_specific float, Spor_cond_1 float, Spor_cond_2 float, Spor_cond_3 float, Spor_cond_4 float, Spor_cond_5 float, Spor_cond_6 float, Compensatie float, 
	VENIT_TOTAL float, Salar_orar float, Venit_cond_normale float, Venit_cond_deosebite float, Venit_cond_speciale float, 
	Spor_cond_7 float, Spor_cond_8 float, Spor_cond_9 float, Spor_cond_10 float)
as
Begin
	declare @datajos datetime, @datasus datetime, @lunaApelare char(2), @marca varchar(6), @nc int
	set @datajos = @parXML.value('(/*/@datajos)[1]', 'datetime')
	set @datasus = @parXML.value('(/*/@datasus)[1]', 'datetime')
	set @lunaApelare = @parXML.value('(/*/@lunaApelare)[1]', 'char(2)')
	set @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
	set @nc = isnull(@parXML.value('(/*/@nc)[1]', 'int'),0)
	
--	formez datele sub forma tabelei brut
	insert into @rectificaribrut
	select b.datalunii, b.Marca, isnull(b.Loc_de_munca,n.Loc_de_munca) as Loc_de_munca, 1 as Loc_munca_pt_stat_de_plata, sum(isnull(Total_ore_lucrate,0)) as Total_ore_lucrate, 
		sum(isnull(Ore_lucrate__regie,0)) as Ore_lucrate__regie, sum(isnull(Realizat__regie,0)) as Realizat__regie, 
		sum(isnull(Ore_lucrate_acord,0)) as Ore_lucrate_acord, sum(isnull(Realizat_acord,0)) as Realizat_acord, 
		sum(isnull(Ore_suplimentare_1,0)) as Ore_suplimentare_1, sum(isnull(Indemnizatie_ore_supl_1,0)) as Indemnizatie_ore_supl_1, 
		sum(isnull(Ore_suplimentare_2,0)) as Ore_suplimentare_2, sum(isnull(Indemnizatie_ore_supl_2,0)) as Indemnizatie_ore_supl_2, 
		sum(isnull(Ore_suplimentare_3,0)) as Ore_suplimentare_3, sum(isnull(Indemnizatie_ore_supl_3,0)) as Indemnizatie_ore_supl_3, 
		sum(isnull(Ore_suplimentare_4,0)) as Ore_suplimentare_4, sum(isnull(Indemnizatie_ore_supl_4,0)) as Indemnizatie_ore_supl_4, 
		sum(isnull(Ore_spor_100,0)) as Ore_spor_100, sum(isnull(Indemnizatie_ore_spor_100,0)) as Indemnizatie_ore_spor_100, 
		sum(isnull(Ore_de_noapte,0)) as Ore_de_noapte, sum(isnull(Ind_ore_de_noapte,0)) as Ind_ore_de_noapte, 
		sum(isnull(Ore_lucrate_regim_normal,0)) as Ore_lucrate_regim_normal, sum(isnull(Ind_regim_normal,0)) as Ind_regim_normal, 
		sum(isnull(Ore_intrerupere_tehnologica,0)) as Ore_intrerupere_tehnologica, sum(isnull(Ind_intrerupere_tehnologica,0)) as Ind_intrerupere_tehnologica, 
		sum(isnull(Ore_obligatii_cetatenesti,0)) as Ore_obligatii_cetatenesti, sum(isnull(Ind_obligatii_cetatenesti,0)) as Ind_obligatii_cetatenesti, 
		sum(isnull(Ore_concediu_fara_salar,0)) as Ore_concediu_fara_salar, sum(isnull(Ind_concediu_fara_salar,0)) as Ind_concediu_fara_salar, 
		sum(isnull(Ore_concediu_de_odihna,0)) as Ore_concediu_de_odihna, sum(isnull(Ind_concediu_de_odihna,0)) as Ind_concediu_de_odihna, 
		sum(isnull(Ore_concediu_medical,0)) as Ore_concediu_medical, sum(isnull(Ind_c_medical_unitate,0)) as Ind_c_medical_unitate, sum(isnull(Ind_c_medical_CAS,0)) as Ind_c_medical_CAS, 
		sum(isnull(Ore_invoiri,0)) as Ore_invoiri, sum(isnull(Ind_invoiri,0)) as Ind_invoiri, sum(isnull(Ore_nemotivate,0)) as Ore_nemotivate, sum(isnull(Ind_nemotivate,0)) as Ind_nemotivate, 
		sum(isnull(Salar_categoria_lucrarii,0)) as Salar_categoria_lucrarii, 
		sum(isnull(CMCAS,0)) as CMCAS, sum(isnull(CMunitate,0)) as CMunitate, sum(isnull(CO,0)) as CO, sum(isnull(Restituiri,0)) as Restituiri, sum(isnull(Diminuari,0)) as Diminuari, 
		sum(isnull(Suma_impozabila,0)) as Suma_impozabila, sum(isnull(Premiu,0)) as Premiu, sum(isnull(Diurna,0)) as Diurna, sum(isnull(Cons_admin,0)) as Cons_admin, 
		sum(isnull(Sp_salar_realizat,0)) as Sp_salar_realizat, sum(isnull(Suma_imp_separat,0)) as Suma_imp_separat, 
		sum(isnull(Spor_vechime,0)) as Spor_vechime, sum(isnull(Spor_de_noapte,0)) as Spor_de_noapte, sum(isnull(Spor_sistematic_peste_program,0)) as Spor_sistematic_peste_program, 
		sum(isnull(Spor_de_functie_suplimentara,0)) as Spor_de_functie_suplimentara, sum(isnull(Spor_specific,0)) as Spor_specific, 
		sum(isnull(Spor_cond_1,0)) as Spor_cond_1, sum(isnull(Spor_cond_2,0)) as Spor_cond_2, sum(isnull(Spor_cond_3,0)) as Spor_cond_3, 
		sum(isnull(Spor_cond_4,0)) as Spor_cond_4, sum(isnull(Spor_cond_5,0)) as Spor_cond_5, sum(isnull(Spor_cond_6,0)) as Spor_cond_6, 
		sum(isnull(Compensatie,0)) as Compensatie, sum(isnull(b.VENIT_TOTAL,0)) as VENIT_TOTAL, max(isnull(Salar_orar,0)) as Salar_orar, 
		sum(isnull(Venit_cond_normale,0)) as Venit_cond_normale, sum(isnull(Venit_cond_deosebite,0)) as Venit_cond_deosebite, sum(isnull(Venit_cond_speciale,0)) as Venit_cond_speciale, 
		sum(isnull(Spor_cond_7,0)) as Spor_cond_7, sum(isnull(Spor_cond_8,0)) as Spor_cond_8, sum(isnull(Spor_cond_9,0)) as Spor_cond_9, max(isnull(Spor_cond_10,0)) as Spor_cond_10
	from
	(select (case when @lunaApelare='LR' and @nc=0 then pr.data_rectificata else ar.data end) as datalunii, 
		(case when @lunaApelare='LR' then pr.data_rectificata else ar.data end) as data, 
		pr.data_rectificata, ar.marca, pr.loc_de_munca, pr.tip_suma, convert(decimal(12,2),pr.suma) as suma, ts.camp_tabela as camp
	from PozRectificariSalarii pr
		inner join AntetRectificariSalarii ar on ar.idRectificare=pr.idRectificare
		left outer join dbo.fTipSumeSalarii() ts on ts.tabela='brut' and ts.tip_suma=pr.tip_suma
	where ts.tabela='brut' and (@lunaApelare='LC' and ar.data between @datajos and @datasus or @lunaApelare='LR' and pr.data_rectificata between @datajos and @datasus)
		and (@marca is null or ar.marca=@marca)) a
		pivot (sum(suma) for camp in 
			(Total_ore_lucrate, Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
			Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3, Indemnizatie_ore_supl_3, Ore_suplimentare_4, Indemnizatie_ore_supl_4, 
			Ore_spor_100, Indemnizatie_ore_spor_100, Ore_de_noapte, Ind_ore_de_noapte, Ore_lucrate_regim_normal, Ind_regim_normal, Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, 
			Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar, Ore_concediu_de_odihna, Ind_concediu_de_odihna, 
			Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, Salar_categoria_lucrarii, 
			CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, Spor_vechime, Spor_de_noapte, 
			Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, 
			Compensatie, VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10)) b
	left outer join net n on n.Data=b.data_rectificata and n.Marca=b.marca		
	group by b.datalunii, b.marca, isnull(b.Loc_de_munca,n.Loc_de_munca)

	return
End
/*
	select * from fRectificariBrut ('11/30/2011', 'LR', null)
*/	
