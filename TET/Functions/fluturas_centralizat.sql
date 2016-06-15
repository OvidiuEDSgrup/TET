--***
/**	functie fluturas centralizat **/
Create function fluturas_centralizat
	(@dataJos datetime,@dataSus datetime,@MarcaJ char(6),@MarcaS char(6),@LmJ char(9),@LmS char(9), @lGrpM int,@cGrpM char(1),
	@lTipSal int,@cTipSalJ char(1),@cTipSalS char(1),@lTipPers int,@cTipPers char(1),@lFunctie int, @cFunctie char(6), @lMand int,@cMand char(6),
	@lCard int,@cCard char(30),@lUnSex int,@Sex int,@lTipStat int,@cTipStat char(200), @AreDrCond int, @cLstCond char(1),@lTipAng int,@cTipAng char(1),
	@lSirMarci int,@cSirMarci char(200),@LmExc char(9), @StrLmExc int,@lGrpMExc int,@Grup char(20),
	@exclLM varchar(20) = null,@setlm varchar(20)=null,@activitate varchar(20)=null)
returns @flutcent table
	(data char(10),Total_ore_lucrate int,Ore_lucrate__regie int,Realizat__regie float,Ore_lucrate_acord float,Realizat_acord float, 
	Ore_suplimentare_1 int,Indemnizatie_ore_supl_1 float,Ore_suplimentare_2 int,Indemnizatie_ore_supl_2 float,Ore_suplimentare_3 float,Indemnizatie_ore_supl_3 float,
	Ore_suplimentare_4 int,Indemnizatie_ore_supl_4 float,Ore_spor_100 int,Indemnizatie_ore_spor_100 float, Ore_de_noapte int,Ind_ore_de_noapte float,
	Ore_lucrate_regim_normal int,Ind_regim_normal float,Ore_intrerupere_tehnologica int, Ind_intrerupere_tehnologica float,Ore_obligatii_cetatenesti int,Ind_obligatii_cetatenesti float,
	Ore_concediu_fara_salar int, Ind_concediu_fara_salar float,Ore_concediu_de_odihna int,Ind_concediu_de_odihna float,
	Ore_concediu_medical int,Ore_ingr_copil int, Ind_c_medical_unitate float,Ind_c_medical_CAS float,CMFAMBP float,CMUnit30Z float,
	Ore_invoiri int,Ind_intrerupere_tehnologica_2 float, Ore_nemotivate int, Ind_conducere float,Salar_categoria_lucrarii float,
	CMCAS float,CMunitate float,CO float,Restituiri float,Diminuari float, Suma_impozabila float,Premiu float,Diurna float,
	Cons_admin float,Sp_salar_realizat float,Suma_imp_separat float,Premiu2 float,Diurna2 float,CO2 float,Avantaje_materiale float,Avantaje_impozabile float,
	Spor_vechime float,Spor_de_noapte float,Spor_sistematic_peste_program float,Spor_de_functie_suplimentara float,Spor_specific float, 
	Spor_cond_1 float,Spor_cond_2 float,Spor_cond_3 float,Spor_cond_4 float,Spor_cond_5 float,Spor_cond_6 float,Aj_deces float, 
	Venit_total float,Spor_cond_7 float,Spor_cond_8 float,CM_incasat float,CO_incasat float,Suma_incasata float,Suma_neimpozabila float, 
	Diferenta_impozit float,Impozit float,Impozit_ipotetic float,Impozit_de_virat float,Pensie_suplimentara_3 float,Baza_somaj_1 float,Somaj_1 float,Asig_sanatate_din_impozit float,Asig_sanatate_din_net float,Asig_sanatate_din_CAS float,
	VENIT_NET float,Avans float,Premiu_la_avans float,Debite_externe float,Rate float,Debite_interne float,Cont_curent float,Cor_U float,Cor_W float,REST_DE_PLATA float,
	CAS_unitate float,Somaj_5 float,Fond_de_risc_1 float, Camera_de_Munca_1 float,Asig_sanatate_pl_unitate float,CCI float,VEN_NET_IN_IMP float,Ded_personala float,
	Ded_pensie_facultativa float,Venit_baza_impozit float,Venit_baza_impozit_scutit float,Baza_CAS_ind float,Baza_CAS_CN float, Baza_CAS_CD float,Baza_CAS_CS float,
	Subventii_somaj_art8076 float,Subventii_somaj_art8576 float,Subventii_somaj_art172 float, Subventii_somaj_legea116 float, 
	Total_angajati int, Ore_intrerupere_tehnologica_1 int, Ore_intrerupere_tehnologica_2 int,Ore_intr_tehn_3 int,
	Baza_somaj_5 float, Baza_somaj_5_FP float,Baza_CASS_unitate float,Baza_CCI float, Baza_Camera_de_munca_1 float,Venit_pensionari_scutiri_somaj float, CCI_Fambp float,
	Baza_CAS_cond_norm_CM float, Baza_CAS_cond_deoseb_CM float,Baza_CAS_cond_spec_CM float,CAS_CM float, Baza_fond_garantare float,Fond_garantare float, 
	Venit_ocazO float,Venit_ocazP float,Deplasari_RN float,
	Nr_tichete float,Val_tichete float, NrTichSupl float,ValTichSupl float, Nr_tichete_acordate float,Val_tichete_acordate float, 
	Ajutor_ridicat_dafora float,Ajutor_cuvenit_dafora float,Prime_avans_dafora float,Avans_CO_dafora float, 
	Nr_sal_per_nedeterminata int, Nr_sal_per_determinata int,Nr_ocazionali int,Nr_ocazP int,Nr_ocazP_AS2 int,Nr_cm_t_part int,Nr_pers_handicap float,
	Ingr_copil int,Nr_salariati_inceput_luna int,Nr_angajati int,Nr_plecati int,Nr_plecati_01 int,Salariati_finalul_lunii int,
	Numar_mediu_salariati float, cas_de_virat float,scut_art_80 float,Scut_art_85 float,Cotiz_hand float, Baza_CASS_AMBP float,
	CASS_AMBP float,Baza_Fambp float, Baza_Fambp_CM float, Total_contributii float,Total_viramente float,Marca char(6),salar_de_incadrare float,
	VenitZilieri float, ImpozitZilieri float, RestPlataZilieri float)
as
begin
	declare @rc int, @CalculCASCorU int
	set @rc=(case when @Grup='MARCA' then 2 else 0 end)
	set @CalculCASCorU=dbo.iauParL('PS','CALCAS-U')

	insert @flutcent
	select max((case when @Grup='AN' then convert(char(10),year(a.data)) 
		else (case when @Grup='LUNA' or @Grup='MARCA' then convert(char(10),a.data,101) else convert(char(10),a.data,101) end) end)),
	sum(b.Total_ore_lucrate),sum(b.Ore_lucrate__regie),sum(b.Realizat__regie),sum(b.Ore_lucrate_acord),sum(b.Realizat_acord),
	sum(b.Ore_supl_1),sum(b.Ind_ore_supl_1),sum(b.Ore_supl_2),sum(b.Ind_ore_supl_2),sum(b.Ore_supl_3),sum(b.Ind_ore_supl_3), sum(b.Ore_supl_4),sum(b.Ind_ore_supl_4),
	sum(b.Ore_spor_100),sum(b.Indemnizatie_ore_spor_100),sum(b.Ore_de_noapte), sum(b.Ind_ore_de_noapte),sum(b.Ore_lucrate_regim_normal),sum(b.Ind_regim_normal),
	sum(b.Ore_intrerupere_tehnologica), sum(b.Ind_intrerupere_tehnologica),sum(b.Ore_obligatii_cetatenesti),sum(b.Ind_obligatii_cetatenesti),sum(b.Ore_concediu_fara_salar), 
	sum(b.Ind_concediu_fara_salar),sum(b.Ore_concediu_de_odihna),sum(b.Ind_concediu_de_odihna),sum(b.Ore_concediu_medical), sum(a.Ore_ingr_copil),
	sum(b.Ind_c_medical_unitate),sum(b.Ind_c_medical_CAS),sum(b.CMFAMBP),sum(a.CMUnit30Z),sum(b.Ore_invoiri), sum(Ind_intrerupere_tehnologica_2),sum(b.Ore_nemotivate),
	sum(b.Ind_conducere),sum(b.Salar_categoria_lucrarii),sum(b.CMCAS),sum(b.CMunitate),sum(b.CO),sum(b.Restituiri),sum(b.Diminuari),sum(b.Suma_impozabila),
	sum(b.Premiu),sum(b.Diurna), sum(b.Cons_admin),sum(b.Sp_salar_realizat),sum(b.Suma_imp_separat),sum(b.Premiu2),sum(b.Diurna2),sum(b.CO2),sum(b.Avantaje_materiale),sum(b.Avantaje_impozabile),
	sum(b.Spor_vechime), sum(b.Spor_de_noapte),sum(b.Spor_sistematic_peste_program),sum(b.Spor_de_functie_suplimentara),sum(b.Spor_specific), 
	sum(b.Spor_cond_1),sum(b.Spor_cond_2),sum(b.Spor_cond_3),sum(b.Spor_cond_4),sum(b.Spor_cond_5),sum(b.Spor_cond_6), sum(b.Aj_deces),
	sum(b.VENIT_TOTAL),sum(b.Spor_cond_7),sum(b.Spor_cond_8),sum(a.CM_incasat),sum(a.CO_incasat), sum(a.Suma_incasata),sum(a.Suma_neimpozabila),
	sum(a.Diferenta_impozit),sum(a.Impozit),sum(a.Impozit_ipotetic),sum(a.Impozit+a.Diferenta_impozit+a.ImpozitZilieri-a.Impozit_ipotetic),
	sum(a.Pensie_suplimentara_3), sum(a.Baza_somaj_1),sum(a.Somaj_1),sum(a.Asig_sanatate_din_impozit),sum(a.Asig_sanatate_din_net),
	sum(a.Asig_sanatate_din_CAS),sum(a.VENIT_NET),sum(a.Avans),sum(a.Premiu_la_avans),sum(a.Debite_externe),sum(a.Rate), sum(a.Debite_interne),sum(a.Cont_curent),sum(b.Cor_U),sum(b.Cor_W),
	sum(a.REST_DE_PLATA),round(sum(a.CAS_unitate),@rc), round(sum(a.Somaj_5),@rc),round(sum(a.Fond_de_risc_1),@rc),round(sum(a.Camera_de_Munca_1),@rc), 
	round(sum(a.Asig_sanatate_pl_unitate),@rc),round(sum(a.CCI),@rc),sum(a.VEN_NET_IN_IMP),sum(a.Ded_personala), sum(a.Ded_pens_fac), 
	sum(a.Venit_baza_imp),sum(a.Venit_baza_imp_scutit),sum(a.Baza_CAS_ind), sum(a.Baza_CAS_cond_norm),sum(a.Baza_CAS_cond_deoseb),sum(a.Baza_CAS_cond_spec), 
	sum(a.Subv_somaj_art8076),sum(a.Subv_somaj_art8576),sum(a.Subv_somaj_art172), sum(Subv_somaj_legea116),
	(case when @Grup='AN' then count(distinct a.Marca) else count(a.Marca) end)-sum(a.Ocazional+(case when a.Ore_ingr_copil<>0 then 1 else 0 end))-sum(a.Zilier), 
	sum(b.ore_intr_tehn_1),sum(b.ore_intr_tehn_2),sum(b.ore_intr_tehn_3),sum(a.Baza_somaj_5),sum(a.Baza_somaj_5_FP), sum(a.Baza_CASS_unitate),sum(a.Baza_CCI),
	sum(a.Baza_Camera_de_munca_1),sum(a.Venit_pensionari_scutiri_somaj), sum(a.CCI_Fambp),sum(a.Baza_CAS_cond_norm_CM),sum(a.Baza_CAS_cond_deoseb_CM),sum(a.Baza_CAS_cond_spec_CM), 
	sum(a.CAS_CM),sum(a.Baza_fgarantare),round(sum(a.Fond_garantare),@rc),sum(a.Ven_ocazO),
	sum(a.Ven_ocazP),sum(b.Deplasari_RN),sum(a.Nr_tichete),sum(a.Val_tichete),sum(a.NrTichSupl),sum(a.ValTichSupl),sum(a.Nr_tichete_acordate),sum(a.Val_tichete_acordate),
	sum(a.Ajutor_ridicat_dafora),sum(a.Ajutor_cuvenit_dafora),sum(a.Prime_avans_dafora),sum(a.Avans_CO_dafora), sum(a.SPNedet),sum(a.SPDet),
	sum(a.Ocazional),sum(a.Ocaz_P),sum(a.Ocaz_P_AS2),sum(a.Cm_t_part),sum(a.Handicap),
	sum(case when a.Ore_ingr_copil<>0 then 1 else 0 end),sum((case when 1-a.Angajat-a.Plecat_01-a.NuSalariat-a.Zilier<0 then 0 else 1-a.Angajat-a.Plecat_01-a.NuSalariat-a.Zilier end)),
	sum(a.Angajat),sum(a.Plecat), sum(a.Plecat_01), sum((case when 1-a.Plecat-a.Plecat_01-a.NuSalariat-a.Zilier<0 then 0 else 1-a.Plecat-a.Plecat_01-a.NuSalariat-a.Zilier end)),
	(case when max(a.Nrms_cnph)<>0 then max(a.Nrms_cnph) else sum(b.Numar_mediu_salariati) end), round(sum(a.cas_de_virat),0),
	sum(a.scut_art_80),sum(a.scut_art_85),max(a.Cotiz_hand),sum(b.Baza_CASS_AMBP),sum(a.CASS_AMBP),
	sum((case when a.Fond_de_risc_1<>0 then a.Baza_CAS_cond_norm+a.Baza_CAS_cond_deoseb+a.Baza_CAS_cond_spec-(a.Baza_CAS_cond_norm_CM+a.Baza_CAS_cond_deoseb_CM+a.Baza_CAS_cond_spec_CM)
		-(case when @CalculCASCorU=1 then b.Cor_U else 0 end) else 0 end)),
	sum((case when year(a.Data)>=2011 then a.Baza_fambp_CM else a.Baza_CAS_cond_norm_CM+a.Baza_CAS_cond_deoseb_CM+a.Baza_CAS_cond_spec_CM end)),
	sum(a.Virament_partial)+sum(a.cas_de_virat)+round(sum(a.Somaj_5),0)-sum(a.Subv_somaj_art8076)-sum(a.Subv_somaj_art8576)- sum(a.Subv_somaj_art172)-sum(a.Scut_art_80)- sum(a.Scut_art_85)
	+round(sum(a.CCI),0)-sum(b.Ind_c_medical_CAS)-sum(b.CMCAS)+sum(a.Asig_sanatate_din_impozit)
	+round(sum(a.CCI_fambp),0)+sum(a.fondrisc_de_virat)+round(sum(a.CASS_AMBP),0)+round(max(a.Cotiz_hand),0) as Total_contributii,
	sum(a.Virament_partial)+(case when sum(a.cas_de_virat)>0 then sum(a.cas_de_virat) else 0 end)
	+(case when (round(sum(a.Somaj_5),0)-sum(a.Subv_somaj_art8076)-sum(a.Subv_somaj_art8576)-sum(a.Subv_somaj_art172)-sum(a.Scut_art_80)- sum(a.Scut_art_85))>0 
		then round(sum(a.Somaj_5),0)-sum(a.Subv_somaj_art8076)-sum(a.Subv_somaj_art8576)-sum(a.Subv_somaj_art172)- sum(a.Scut_art_80)-sum(a.Scut_art_85) else 0 end)
	+(case when (round(sum(a.CCI),0)+round(sum(a.CCI_fambp),0)-sum(b.Ind_c_medical_CAS)-sum(b.CMCAS))>0 then round(sum(a.CCI),0)+round(sum(a.CCI_fambp),0)
	-sum(b.Ind_c_medical_CAS)-sum(b.CMCAS) else 0 end)+
	+sum(a.Asig_sanatate_din_impozit)+(case when sum(a.fondrisc_de_virat)>0 then sum(a.fondrisc_de_virat) else 0 end)+max(a.Cotiz_hand)+round(sum(a.CASS_AMBP),0) as Total_viramente,
	max(case when @Grup='MARCA' then a.marca else '' end),round(sum(b.salar_de_incadrare),0),
	round(sum(a.VenitZilieri),0), round(sum(ImpozitZilieri),0), round(sum(RestPlataZilieri),0)
	from dbo.fluturas_centralizat_net(@dataJos,@dataSus,@MarcaJ,@MarcaS,@LmJ,@LmS,@lGrpM,@cGrpM,@lTipSal, @cTipSalJ,@cTipSalS,@lTipPers,@cTipPers,@lFunctie,@cFunctie,
			@lMand,@cMand,@lCard,@cCard,@lUnSex,@Sex, @lTipStat,@cTipStat,@AreDrCond,@cLstCond,@lTipAng,@cTipAng,@lSirMarci,@cSirMarci,@LmExc,@StrLmExc,@lGrpMExc,@Grup,@exclLM,@setlm,@activitate) a 
		left outer join dbo.fluturas_centralizat_brut(@dataJos,@dataSus,@MarcaJ,@MarcaS,@LmJ,@LmS,@lGrpM,@cGrpM,@lTipSal, @cTipSalJ,@cTipSalS,@lTipPers,@cTipPers,@lFunctie,@cFunctie,
			@lMand,@cMand,@lCard,@cCard,@lUnSex,@Sex, @lTipStat,@cTipStat,@AreDrCond,@cLstCond,@lTipAng,@cTipAng,@lSirMarci,@cSirMarci,@LmExc,@StrLmExc,@lGrpMExc,@exclLM,@setlm,@activitate) b 
				on b.data=a.data and b.marca=a.marca and a.Zilier=0
	group by (case when @Grup='AN' then year(a.data) else (case when @Grup='LUNA' or @Grup='MARCA' then a.data else '' end) end),(case when @Grup='MARCA' then a.Marca else '' end)
	return
end
