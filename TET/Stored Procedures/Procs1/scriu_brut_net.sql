--***
/**	proc. scriu brut net corectii	*/
create procedure scriu_brut_net
	@datajos datetime, @datasus datetime, @marca char(6), @loc_de_munca char(9), @CMCAS float, @CMUnitate float, @CO float, @Restituiri float, @Diminuari float, @Suma_impoz float, @Premiu float, 
	@Diurna float, @Cons_admin float, @Procent_lucrat_acord float, @Suma_imp_sep float, @Aj_deces float, @Regim_de_lucru float, @CM_incasat float, @CO_incasat float, @Suma_incasata float, 
	@Suma_neimp float, @Dif_impozit float
As
Begin
	if exists (select * from brut where data=@datasus and marca=@marca and loc_de_munca=@loc_de_munca)
		update brut set CMCAS = CMCAS+@CMCAS, CMunitate = CMunitate+@CMUnitate, CO = CO+@CO, Restituiri = Restituiri+@Restituiri, Diminuari = Diminuari+@Diminuari, 
			Suma_impozabila = Suma_impozabila+@Suma_impoz, Premiu = Premiu+@Premiu, Diurna = Diurna+@Diurna, Cons_admin = Cons_admin+@Cons_admin, 
			Sp_salar_realizat = Sp_salar_realizat+@Procent_lucrat_acord, Suma_imp_separat = Suma_imp_separat+@Suma_imp_sep, Compensatie = Compensatie+@Aj_deces, 
			Spor_cond_10 = @Regim_de_lucru
		where marca = @marca and data = @datasus and loc_de_munca = @loc_de_munca

	if not exists (select * from brut where data=@datasus and marca=@marca and loc_de_munca=@loc_de_munca)
		insert into brut (Data,Marca,Loc_de_munca,Loc_munca_pt_stat_de_plata,Total_ore_lucrate,Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
		Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3,Indemnizatie_ore_supl_3, Ore_suplimentare_4,
		Indemnizatie_ore_supl_4,Ore_spor_100, Indemnizatie_ore_spor_100,Ore_de_noapte,Ind_ore_de_noapte, Ore_lucrate_regim_normal,Ind_regim_normal, 
		Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar,
		Ore_concediu_de_odihna, Ind_concediu_de_odihna, Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, 
		Salar_categoria_lucrarii, CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, Spor_vechime, Spor_de_noapte, 
		Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, VENIT_TOTAL, 
		Salar_orar,	Venit_cond_normale,Venit_cond_deosebite,Venit_cond_speciale,Spor_cond_7,Spor_cond_8,Spor_cond_9,Spor_cond_10)
		select @datasus, @marca, @loc_de_munca, 0 as locm_statpl, 0, 0, 0, 0, 0, 0 as Os1, 0, 0, 0, 0, 0, 0, 0,	0 as O100, 0, 0 as Oren, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 as ore_CO, 0, 
		0 as ore_CM, 0, 0, 0, 0, 0, 0, 0 as sal_catl, @CMCAS, @CMUnitate, @CO, @Restituiri, @Diminuari, @Suma_impoz, @Premiu, @Diurna, @Cons_admin, @Procent_lucrat_acord, @Suma_imp_sep, 
		0 as Spv, 0, 0, 0, 0, 0 as Sp1, 0, 0, 0, 0, 0, @Aj_deces, 0, 0, 0, 0, 0, 0, 0, 0, @Regim_de_lucru

	if exists (select * from net where data=@datasus and marca=@marca)
		update net set CM_incasat = CM_incasat+@CM_incasat, CO_incasat = CO_incasat+@CO_incasat, Suma_incasata = Suma_incasata+@Suma_incasata, Suma_neimpozabila = Suma_neimpozabila+@Suma_neimp, 
		Diferenta_impozit = Diferenta_impozit+@Dif_impozit
		where marca = @marca and data = @datasus

	if not exists (select * from net where data=@datasus and marca=@marca)
		insert into net(Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
		Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, CAS,
		Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
		VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)
		select @datasus, @marca, @loc_de_munca, 0 as VT, @CM_incasat, @CO_incasat, @Suma_incasata, @Suma_neimp, @Dif_impozit, 0 as Impozit, 0, 0, 0, 0, 0, 0, 0 as Avans, 0, 0 as Deb, 0, 0, 0, 
		0 as RP, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 as VN, 0, 0, 0 as Vbc, 0, 0, 0, 0, 0
End
