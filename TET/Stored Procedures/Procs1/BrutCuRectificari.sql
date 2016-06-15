/*
		procedura permite obtinerea unei rezultat cu structura tabelei net, unind datele din tabela brut si rectificari pe tabela brut
*/
Create procedure BrutCuRectificari @parXML xml
as
/*
	@locapelare='LR' - > apelare procedura din luna rectificata (inchisa dpdv. contabil) - cea pe care se declara diferentele in D112
	@locapelare='LC' - > apelare procedura din luna curenta - cea pe care se inregistreaza contabil diferentele
*/	
Begin try
	declare @utilizator varchar(20), @lista_lm int, @multiFirma int, @datajos datetime, @datasus datetime, @lunaApelare char(2), @lm varchar(9), 
		@GruparePeMarca int, @GrupareRemarul int, @parXMLRectif xml, @ceselectez int, @nc int
/*
	@ceselectez=0 -> se selecteaza atat datele din brut cat si cele ce provin din rectificari
	@ceselectez=1 -> se selecteaza DOAR datele din BRUT
	@ceselectez=2 -> se selecteaza DOAR datele din rectificari
*/
	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @datajos = @parXML.value('(/*/@datajos)[1]', 'datetime')
	set @datasus = @parXML.value('(/*/@datasus)[1]', 'datetime')
	set @lunaApelare = @parXML.value('(/*/@lunaApelare)[1]', 'char(2)')
	set @lm = @parXML.value('(/*/@lm)[1]', 'varchar(9)')
	set @GruparePeMarca = isnull(@parXML.value('(/*/@gruparepemarca)[1]', 'int'),0)
	set @GrupareRemarul = isnull(@parXML.value('(/*/@grupareremarul)[1]', 'int'),0)
	set @ceselectez = isnull(@parXML.value('(/*/@ceselectez)[1]', 'int'),0)
	set @nc = @parXML.value('(/*/@nc)[1]', 'int')

--	creez tabele temporare #rectificaribrut si #rectificarinet cu structura similara tabelelor brut si net in care pun diferentele rezultate din rectificari
	if object_id('tempdb..#rectificaribrut') is not null drop table #rectificaribrut
	
	select top 0 Data, Marca, Loc_de_munca, Loc_munca_pt_stat_de_plata, Total_ore_lucrate, Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
		Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3, Indemnizatie_ore_supl_3, Ore_suplimentare_4, 
		Indemnizatie_ore_supl_4, Ore_spor_100, Indemnizatie_ore_spor_100, Ore_de_noapte, Ind_ore_de_noapte, Ore_lucrate_regim_normal, Ind_regim_normal, 
		Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar, 
		Ore_concediu_de_odihna, Ind_concediu_de_odihna, Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, 
		Salar_categoria_lucrarii, CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, 
		Spor_vechime, Spor_de_noapte, Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, 
		Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, 
		VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10
	into #rectificaribrut from brut where data between @datajos and @datasus

	set @parXMLRectif=(select @datajos datajos, @dataSus datasus, @lunaApelare lunaApelare, @nc nc for xml raw)
	if @ceselectez in (0,2)
		insert into #rectificaribrut
		select Data, Marca, Loc_de_munca, Loc_munca_pt_stat_de_plata, Total_ore_lucrate, Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
			Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3, Indemnizatie_ore_supl_3, Ore_suplimentare_4, 
			Indemnizatie_ore_supl_4, Ore_spor_100, Indemnizatie_ore_spor_100, Ore_de_noapte, Ind_ore_de_noapte, Ore_lucrate_regim_normal, Ind_regim_normal, 
			Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar, 
			Ore_concediu_de_odihna, Ind_concediu_de_odihna, Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, 
			Salar_categoria_lucrarii, CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, 
			Spor_vechime, Spor_de_noapte, Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, 
			Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, 
			VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10
		from dbo.fRectificariBrut (@parXMLRectif) 

--	unesc tabelele brut si #rectificaribrut, respectiv net si #rectificarinet si se obtin tabelele #brut si #net 
	select b.data, b.marca, (case when @GruparePeMarca=1 then '' when @GrupareRemarul=1 then left(b.Loc_de_munca,3) else b.Loc_de_munca end) as Loc_de_munca, 
		max(convert(char(1),Loc_munca_pt_stat_de_plata)) as Loc_munca_pt_stat_de_plata,
		sum(Total_ore_lucrate) as Total_ore_lucrate, sum(Ore_lucrate__regie) as Ore_lucrate__regie, sum(Realizat__regie) as Realizat__regie, 
		sum(Ore_lucrate_acord) as Ore_lucrate_acord, sum(Realizat_acord) as Realizat_acord, 
		sum(Ore_suplimentare_1) as Ore_suplimentare_1, sum(Indemnizatie_ore_supl_1) as Indemnizatie_ore_supl_1, 
		sum(Ore_suplimentare_2) as Ore_suplimentare_2, sum(Indemnizatie_ore_supl_2) as Indemnizatie_ore_supl_2, 
		sum(Ore_suplimentare_3) as Ore_suplimentare_3, sum(Indemnizatie_ore_supl_3) as Indemnizatie_ore_supl_3, 
		sum(Ore_suplimentare_4) as Ore_suplimentare_4, sum(Indemnizatie_ore_supl_4) as Indemnizatie_ore_supl_4, 
		sum(ore_spor_100) as ore_spor_100, sum(Indemnizatie_ore_spor_100) as Indemnizatie_ore_spor_100, 
		sum(Ore_de_noapte) as Ore_de_noapte, sum(Ind_ore_de_noapte) as Ind_ore_de_noapte, 
		sum(Ore_lucrate_regim_normal) as Ore_lucrate_regim_normal, sum(Ind_regim_normal) as Ind_regim_normal, 
		sum(Ore_intrerupere_tehnologica) as Ore_intrerupere_tehnologica, sum(Ind_intrerupere_tehnologica) as Ind_intrerupere_tehnologica, 
		sum(Ore_obligatii_cetatenesti) as Ore_obligatii_cetatenesti, sum(Ind_obligatii_cetatenesti) as Ind_obligatii_cetatenesti, 
		sum(Ore_concediu_fara_salar) as Ore_concediu_fara_salar, sum(Ind_concediu_fara_salar) as Ind_concediu_fara_salar,
		sum(Ore_concediu_de_odihna) as Ore_concediu_de_odihna, sum(Ind_concediu_de_odihna) as Ind_concediu_de_odihna, 
		sum(Ore_concediu_medical) as Ore_concediu_medical, sum(Ind_c_medical_unitate) as Ind_c_medical_unitate, sum(Ind_c_medical_CAS) as Ind_c_medical_CAS, 
		sum(Ore_invoiri) as Ore_invoiri, sum(Ind_invoiri) as Ind_invoiri, sum(Ore_nemotivate) as Ore_nemotivate, sum(Ind_nemotivate) as Ind_nemotivate, 
		sum(Salar_categoria_lucrarii) as Salar_categoria_lucrarii, 
		sum(CMCAS) as CMCAS, sum(CMunitate) as CMunitate, sum(CO) as CO, sum(Restituiri) as Restituiri, 
		sum(Diminuari) as Diminuari, sum(Suma_impozabila) as Suma_impozabila, sum(Premiu) as Premiu, sum(Diurna) as Diurna, 
		sum(Cons_admin) as Cons_admin, sum(Sp_salar_realizat) as Sp_salar_realizat, sum(Suma_imp_separat) as Suma_imp_separat, 
		sum(b.Spor_vechime) as Spor_vechime, sum(b.Spor_de_noapte) as Spor_de_noapte, sum(b.Spor_sistematic_peste_program) as Spor_sistematic_peste_program, 
		sum(b.Spor_de_functie_suplimentara) as Spor_de_functie_suplimentara, sum(b.Spor_specific) as Spor_specific, 
		sum(Spor_cond_1) as Spor_cond_1, sum(Spor_cond_2) as Spor_cond_2, sum(Spor_cond_3) as Spor_cond_3, sum(Spor_cond_4) as Spor_cond_4, 
		sum(Spor_cond_5) as Spor_cond_5, sum(Spor_cond_6) as Spor_cond_6, sum(Compensatie) as Compensatie, sum(VENIT_TOTAL) as VENIT_TOTAL, max(salar_orar) as Salar_orar, 
		sum(Venit_cond_normale) as Venit_cond_normale, sum(Venit_cond_deosebite) as Venit_cond_deosebite, sum(Venit_cond_speciale) as Venit_cond_speciale, 
		sum(Spor_cond_7) as Spor_cond_7, sum(Spor_cond_8) as Spor_cond_8, sum(Spor_cond_9) as Spor_cond_9, max(Spor_cond_10) as Spor_cond_10
	from 
		(select Data, Marca, Loc_de_munca, Loc_munca_pt_stat_de_plata, Total_ore_lucrate, Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
			Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3, Indemnizatie_ore_supl_3, Ore_suplimentare_4, 
			Indemnizatie_ore_supl_4, Ore_spor_100, Indemnizatie_ore_spor_100, Ore_de_noapte, Ind_ore_de_noapte, Ore_lucrate_regim_normal, Ind_regim_normal, 
			Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar, 
			Ore_concediu_de_odihna, Ind_concediu_de_odihna, Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, 
			Salar_categoria_lucrarii, CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, 
			Spor_vechime, Spor_de_noapte, Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, 
			Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, 
			VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10 
		from brut where data between @datajos and @datasus and @ceselectez in (0,1)
		union all 
		select Data, Marca, Loc_de_munca, Loc_munca_pt_stat_de_plata, Total_ore_lucrate, Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
			Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3, Indemnizatie_ore_supl_3, Ore_suplimentare_4, 
			Indemnizatie_ore_supl_4, Ore_spor_100, Indemnizatie_ore_spor_100, Ore_de_noapte, Ind_ore_de_noapte, Ore_lucrate_regim_normal, Ind_regim_normal, 
			Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar, 
			Ore_concediu_de_odihna, Ind_concediu_de_odihna, Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, 
			Salar_categoria_lucrarii, CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, 
			Spor_vechime, Spor_de_noapte, Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, 
			Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, 
			VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10 
		from #rectificaribrut) b
		left outer join istPers i on i.Data=b.Data and i.Marca=b.Marca 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where (@multiFirma=0 and @nc=1 or @lista_lm=0 or lu.cod is not null) 
	group by b.data, b.marca, (case when @GruparePeMarca=1 then '' when @GrupareRemarul=1 then left(b.Loc_de_munca,3) else b.Loc_de_munca end)

	if object_id('tempdb..#rectificaribrut') is not null drop table #rectificaribrut
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura BrutCuRectificari (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	declare @parXML xml
	set @parXML='<row datajos="2012-01-31" datasus="2012-12-31" lunaApelare="LC" grupareremarul="0" />'
	exec BrutCuRectificari @parXML
*/	
