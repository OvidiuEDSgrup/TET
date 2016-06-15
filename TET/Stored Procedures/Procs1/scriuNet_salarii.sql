--***
/**	proc. scriu net salarii	*/
Create procedure scriuNet_salarii
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @pLoc_de_munca char(9)='', @VENIT_TOTAL float=0, @CM_incasat float=0, @CO_incasat float=0, @Suma_incasata float=0, 
	@Suma_neimp float=0, @Dif_impozit float=0, @Impozit float=0, @Pensie_suplimentara_3 float=0, @Somaj_1 float=0, @Asig_sanatate_din_impozit float=0, @Asig_sanatate_din_net float=0, 
	@Asig_sanatate_din_CAS float=0, @VENIT_NET float=0, @Avans float=0, @Premiu_la_avans float=0, @Debite_externe float=0, @Rate float=0, @Debite_interne float=0, @Cont_curent float=0, 
	@REST_DE_PLATA float=0, @CAS float=0, @Somaj_5 float=0, @Fond_de_risc_1 float=0, @Camera_de_Munca_1 float=0, @Asig_sanatate_pl_unitate float=0, @Coef_tot_ded float=0, @Grad_invalid char(1)='', 
	@Coef_invalid float=0, @Alte_surse int=0, @VEN_NET_IN_IMP float=0, @Ded_baza float=0, @Ded_suplim float=0, @VENIT_BAZA float=0, @Chelt_prof float=0, 
	@Baza_CAS float=0, @Baza_CAS_cond_norm float=0, @Baza_CAS_cond_deoseb float=0, @Baza_CAS_cond_spec float=0, @Lichidare int=0
As
if exists (select * from net where Data=@dataSus and Marca=@pMarca)
	update net set Loc_de_munca=@pLoc_de_munca, VENIT_TOTAL=@VENIT_TOTAL, CM_incasat=CM_incasat+@CM_incasat, CO_incasat=CO_incasat+@CO_incasat, Suma_incasata=Suma_incasata+@Suma_incasata, 
		Suma_neimpozabila=Suma_neimpozabila+@Suma_neimp, Diferenta_impozit=Diferenta_impozit+@Dif_impozit, Impozit=@Impozit, Pensie_suplimentara_3=@Pensie_suplimentara_3, 
		Somaj_1=@Somaj_1,Asig_sanatate_din_impozit=@Asig_sanatate_din_impozit, Asig_sanatate_din_net=@Asig_sanatate_din_net, Asig_sanatate_din_CAS=@Asig_sanatate_din_CAS, 
		VENIT_NET=@VENIT_NET, Avans=(case when @Lichidare=1 then Avans 	else @Avans end), Premiu_la_avans=(case when @Lichidare=1 then Premiu_la_avans else @Premiu_la_avans end), 
		Debite_externe=@Debite_externe, Rate=@Rate, Debite_interne=@Debite_interne, Cont_curent=@Cont_curent, REST_DE_PLATA=@REST_DE_PLATA, 
		CAS=@CAS, Somaj_5=@Somaj_5, Fond_de_risc_1=@Fond_de_risc_1, Camera_de_Munca_1=@Camera_de_Munca_1, Asig_sanatate_pl_unitate=@Asig_sanatate_pl_unitate, 
		Coef_tot_ded=@Coef_tot_ded, Grad_invalid=@Grad_invalid, Coef_invalid=@Coef_invalid, Alte_surse=@Alte_surse, 
		VEN_NET_IN_IMP=@VEN_NET_IN_IMP, Ded_baza=@Ded_baza, Ded_suplim=@Ded_suplim, VENIT_BAZA=@VENIT_BAZA,Chelt_prof=@Chelt_prof,
		Baza_CAS=@Baza_CAS, Baza_CAS_cond_norm=@Baza_CAS_cond_norm, Baza_CAS_cond_deoseb=@Baza_CAS_cond_deoseb, Baza_CAS_cond_spec=@Baza_CAS_cond_spec
	where Marca=@pMarca and Data=@dataSus
if not exists (select * from net where Data=@dataSus and Marca=@pMarca)
	insert into net 
	(Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
	Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
	CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
	VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)
	select @dataSus, @pMarca, @pLoc_de_munca, @VENIT_TOTAL, @CM_incasat, @CO_incasat, @Suma_incasata, @Suma_neimp, @Dif_impozit, @Impozit, @Pensie_suplimentara_3, @Somaj_1, 
	@Asig_sanatate_din_impozit, @Asig_sanatate_din_net, @Asig_sanatate_din_CAS, @VENIT_NET, @Avans, @Premiu_la_avans, @Debite_externe, @Rate, @Debite_interne, @Cont_curent, @REST_DE_PLATA, 
	@CAS, @Somaj_5, @Fond_de_risc_1, @Camera_de_Munca_1, @Asig_sanatate_pl_unitate, @Coef_tot_ded, @Grad_invalid, @Coef_invalid, @Alte_surse, 
	@VEN_NET_IN_IMP, @Ded_baza, @Ded_suplim, @VENIT_BAZA, @Chelt_prof, @Baza_CAS, @Baza_CAS_cond_norm, @Baza_CAS_cond_deoseb, @Baza_CAS_cond_spec
