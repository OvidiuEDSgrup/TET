--***
/**	procedura calcul brut	*/
Create procedure pInsert_brut
	@dataJos datetime, @dataSus datetime, @MarcaJos char(6), @MarcaSus char(6), @LocmJos char(9), @LocmSus char(9)
As
Begin try
	declare @Ore_luna float, @OreM_luna float, @Salar_min float, @SomajTehnic int, 
	@COEV_macheta int, @ScadOS_RN int, @ScadO100_RN int, @ORegieFaraOS2 int, @Adun_OIT_RN int, @ScadOS_OReg int, @ProcOS1 float, @ProcOS2 float, @ProcOS3 float,@ProcOS4 float,@ProcIT1 float,@ProcIT2 float, 
	@NuSpc_OIT float, @Spsp_proc_suma int, @Baza_Spsp float, @Indc_Spsp int, @OS1_OreM int, @OS2_OreM int, @Anul_spv_1zinem int, @Spsp_oreRN int, @Spsp_suma int, @Indc_suma int, @Spsp_proc_unit int,
	@Proc_Spsp float, @Spsp_salim int, 	@SpCondOL int, @SpCond1OL int, @SpCond2OL int, @SpCond3OL int, @SpCond4OL int, @SpCond5OL int, @SpCond6OL int, 
	@Sp1_suma int, @Sp2_suma int,@Sp3_suma int,@Sp4_suma int,@Sp5_suma int,@Sp6_suma int, @Spc_sumafixa int, @Sp1_sumazi int, @Sp1_oreg int,@Sp2_oreac int, @Spc_O100 int, @sp6_oreLuna int, 
	@Sp6_procsuma int,@Suma_bazasp6 int, @O100_Find int, @Indspl_acordind int, @Buget int, @Plata_ora int, @Indicip_lm int, @CorL_SREAC int, @ProcAC_regie float, 
	@Dafora int, @Pasmatex int, @Drumco int, @Somesana int, @Salubris int, @Colas int, @Elite int, @Eurosimex int, @Acumulato int, @DSVET int, @ARLCJ int, @Drumor int, @Gencom int

--	parametrii lunari
	set @Ore_luna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @OreM_luna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
	set @Salar_min=dbo.iauParLN(@dataSus,'PS','S-MIN-BR')
	set @SomajTehnic=dbo.iauParLL(@dataSus,'PS','STOUG28')
--	parametrii
	select @COEV_macheta=max(case when parametru='COEVMCO' then Val_logica else 0 end),
		@ScadOS_RN=max(case when parametru='OSNRN' then Val_logica else 0 end),
		@ScadO100_RN=max(case when parametru='O100NRN' then Val_logica else 0 end),
		@ORegieFaraOS2=max(case when parametru='OREG-FOS2' then Val_logica else 0 end),
		@Adun_OIT_RN=max(case when parametru='OINTNRN' then Val_logica else 0 end),
		@ScadOS_OReg=max(case when parametru='SPL-REGIE' then Val_logica else 0 end),
		@ProcOS1=max(case when parametru='OSUPL1' then Val_numerica else 0 end),
		@ProcOS2=max(case when parametru='OSUPL2' then Val_numerica else 0 end),
		@ProcOS3=max(case when parametru='OSUPL3' then Val_numerica else 0 end),
		@ProcOS4=max(case when parametru='OSUPL4' then Val_numerica else 0 end),
		@ProcIT1=max(case when parametru='PROCINT' then Val_numerica else 0 end),
		@ProcIT2=max(case when parametru='PROC2INT' then Val_numerica else 0 end),
		@NuSpc_OIT=max(case when parametru='SP-C-NUIT' then Val_logica else 0 end),
		@Spsp_proc_suma=max(case when parametru='SSPEC' then Val_logica else 0 end),
		@Baza_Spsp=max(case when parametru='SSPEC' then Val_numerica else 0 end),
		@Indc_Spsp=max(case when parametru='SPSP-IND' then Val_logica else 0 end),
		@OS1_OreM=max(case when parametru='OS1-MED' then Val_logica else 0 end),
		@OS2_OreM=max(case when parametru='OS2-MED' then Val_logica else 0 end),
		@Anul_spv_1zinem=max(case when parametru='SP-V-ANUL' then Val_logica else 0 end),		
		@Spsp_oreRN=max(case when parametru='SP-S-ORN' then Val_logica else 0 end),
		@Spsp_suma=max(case when parametru='SSP-SUMA' then Val_logica else 0 end),
		@Indc_suma=max(case when parametru='INDC-SUMA' then Val_logica else 0 end),
		@Spsp_proc_unit=max(case when parametru='PROCSSPEC' then Val_logica else 0 end),		
		@Proc_Spsp=max(case when parametru='PROCSSPEC' then Val_numerica else 0 end),
		@Spsp_salim=max(case when parametru='SP-S-SINC' then Val_logica else 0 end),
		@SpCondOL=max(case when parametru='SCONDOL' then Val_logica else 0 end),
		@SpCond1OL=max(case when parametru='SCOND1' then Val_logica else 0 end),
		@SpCond2OL=max(case when parametru='SCOND2' then Val_logica else 0 end),
		@SpCond3OL=max(case when parametru='SCOND3' then Val_logica else 0 end),
		@SpCond4OL=max(case when parametru='SCOND4' then Val_logica else 0 end),
		@SpCond5OL=max(case when parametru='SCOND5' then Val_logica else 0 end),
		@SpCond6OL=max(case when parametru='SCOND6' then Val_logica else 0 end),
		@Sp1_suma=max(case when parametru='SC1-SUMA' then Val_logica else 0 end),
		@Sp2_suma=max(case when parametru='SC2-SUMA' then Val_logica else 0 end),
		@Sp3_suma=max(case when parametru='SC3-SUMA' then Val_logica else 0 end),
		@Sp4_suma=max(case when parametru='SC4-SUMA' then Val_logica else 0 end),
		@Sp5_suma=max(case when parametru='SC5-SUMA' then Val_logica else 0 end),
		@Sp6_suma=max(case when parametru='SC6-SUMA' then Val_logica else 0 end),
		@Spc_sumafixa=max(case when parametru='SPCONDSFR' then Val_logica else 0 end),
		@Sp1_sumazi=max(case when parametru='SP1-S1ZI' then Val_logica else 0 end),	
		@Sp1_oreg=max(case when parametru='SC1-ORERG' then Val_logica else 0 end),
		@Sp2_oreac=max(case when parametru='SC2-OREAC' then Val_logica else 0 end),
		@Spc_O100=max(case when parametru='SP-C-O100' then Val_logica else 0 end),
		@sp6_oreLuna=max(case when parametru='SCOND6OLL' then Val_logica else 0 end),
		@Sp6_procsuma=max(case when parametru='SCOND6%SF' then Val_logica else 0 end),
		@Suma_bazasp6=max(case when parametru='SCOND6%SF' then Val_numerica else 0 end),
		@O100_Find=max(case when parametru='O100-FIND' then Val_logica else 0 end),
		@Indspl_acordind=max(case when parametru='ACI-INDOS' then Val_logica else 0 end),
		@Buget=max(case when parametru='UNITBUGET' then Val_logica else 0 end),
		@Plata_ora=max(case when parametru='SALOR-REG' then Val_logica else 0 end),
		@Indicip_lm=max(case when parametru='INDICIPLM' then Val_logica else 0 end),
		@CorL_SREAC=max(case when parametru='SREAC-L' then Val_logica else 0 end),
		@ProcAC_regie=max(case when parametru='REGIE-%' then Val_numerica else 0 end),
		@Dafora=max(case when parametru='DAFORA' then Val_logica else 0 end),
		@Pasmatex=max(case when parametru='PASMATEX' then Val_logica else 0 end),
		@Drumco=max(case when parametru='DRUMCO' then Val_logica else 0 end),
		@Somesana=max(case when parametru='SOMESANA' then Val_logica else 0 end),
		@Salubris=max(case when parametru='SALUBRIS' then Val_logica else 0 end),
		@Colas=max(case when parametru='COLAS' then Val_logica else 0 end),		
		@Elite=max(case when parametru='ELITE' then Val_logica else 0 end),
		@Eurosimex=max(case when parametru='EUROSIMEX' then Val_logica else 0 end),
		@Acumulato=max(case when parametru='ACUMULATO' then Val_logica else 0 end),
		@DSVET=max(case when parametru='DSVET' then Val_logica else 0 end),
		@ARLCJ=max(case when parametru='ARLCJ' then Val_logica else 0 end),
		@Drumor=max(case when parametru='DRUMOR' then Val_logica else 0 end),
		@Gencom=max(case when parametru='GENCOM' then Val_logica else 0 end)
	from par where tip_parametru in ('PS','SP') and parametru in ('COEVMCO','OSNRN','O100NRN','OREG-FOS2','OINTNRN','SPL-REGIE','OSUPL1','OSUPL2','OSUPL3','OSUPL4',
		'PROCINT','PROC2INT','SP-C-NUIT','SSPEC','SPSP-IND','OS1-MED','OS2-MED','SP-V-ANUL',
		'SP-S-ORN','SSP-SUMA','INDC-SUMA','PROCSSPEC','SP-S-SINC','SCONDOL','SCOND1','SCOND2','SCOND3','SCOND4','SCOND5','SCOND6',
		'SC1-SUMA','SC2-SUMA','SC3-SUMA','SC4-SUMA','SC5-SUMA','SC6-SUMA','SPCONDSFR','SP1-S1ZI','SC1-ORERG','SC2-OREAC','SP-C-O100','SCOND6OLL','SCOND6%SF','O100-FIND','ACI-INDOS',
		'UNITBUGET','SALOR-REG','INDICIPLM','SREAC-L','REGIE-%',
		'DAFORA','PASMATEX','DRUMCO','SOMESANA','SALUBRIS','COLAS','ELITE','EUROSIMEX','ACUMULATO','DSVET','ARLCJ','DRUMOR','GENCOM')

	set @Sp1_oreg=(case when @Sp1_oreg=1 then 0 else 1 end)
	set @Sp2_oreac=(case when @Sp2_oreac=1 then 0 else 1 end)	
	set @NuSpc_OIT=(case when @Pasmatex=1 or @NuSpc_OIT=1 then 0 else @ProcIT1 end)
	set @Sp1_sumazi=(case when @Sp1_sumazi=1 or @ARLCJ=1 then 1 else 0 end)	
	set @Elite=(case when @Elite=1 then 0 else 1 end)
	set @Acumulato=(case when @Acumulato=1 then 0 else 1 end)
	select @ScadOS_RN=-1*@ScadOS_RN, @ScadO100_RN=-1*@ScadO100_RN, @ORegieFaraOS2=(case when @ORegieFaraOS2=1 then 0 else 1 end), @ScadOS_OReg=-1*@ScadOS_OReg

	insert into brut (Data,Marca,Loc_de_munca,Loc_munca_pt_stat_de_plata,Total_ore_lucrate,Ore_lucrate__regie,Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
	Ore_suplimentare_1,Indemnizatie_ore_supl_1,Ore_suplimentare_2,Indemnizatie_ore_supl_2,Ore_suplimentare_3,Indemnizatie_ore_supl_3,Ore_suplimentare_4,Indemnizatie_ore_supl_4,
	Ore_spor_100,Indemnizatie_ore_spor_100,Ore_de_noapte,Ind_ore_de_noapte,Ore_lucrate_regim_normal,Ind_regim_normal, Ore_intrerupere_tehnologica,Ind_intrerupere_tehnologica,
	Ore_obligatii_cetatenesti,Ind_obligatii_cetatenesti, Ore_concediu_fara_salar,Ind_concediu_fara_salar,Ore_concediu_de_odihna,Ind_concediu_de_odihna,
	Ore_concediu_medical,Ind_c_medical_unitate,Ind_c_medical_CAS,Ore_invoiri,Ind_invoiri,Ore_nemotivate,Ind_nemotivate,Salar_categoria_lucrarii, CMCAS,CMunitate,CO,Restituiri,Diminuari,
	Suma_impozabila,Premiu,Diurna,Cons_admin,Sp_salar_realizat,Suma_imp_separat, Spor_vechime,Spor_de_noapte,Spor_sistematic_peste_program,Spor_de_functie_suplimentara,Spor_specific,
	Spor_cond_1, Spor_cond_2,Spor_cond_3,Spor_cond_4,Spor_cond_5,Spor_cond_6,Compensatie,VENIT_TOTAL,Salar_orar, 
	Venit_cond_normale,Venit_cond_deosebite,Venit_cond_speciale,Spor_cond_7,Spor_cond_8,Spor_cond_9,Spor_cond_10) 
	select @dataSus,a.Marca,a.Loc_de_munca,convert(bit,max(convert(char(1),a.loc_munca_pentru_stat_de_plata))),sum(c.ore_lucrate), 
	sum(a.Ore_regie+@ScadOS_OReg*(a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4)), 
	round(sum((case when a.tip_salarizare>5 then 0 else 1 end)* (a.ore_regie+@ScadOS_OReg*(a.ore_suplimentare_1+a.ore_suplimentare_2+a.ore_suplimentare_3+ a.ore_suplimentare_4))*
	(case when @Dafora=1 and a.salar_categoria_lucrarii<>0 then a.salar_categoria_lucrarii 
		else (case when @Plata_ora=1 and b.salar_lunar_de_baza<>0 then b.salar_lunar_de_baza/@Ore_luna else c.salar_orar end) end)
	*(case when @Indicip_lm=1 and a.tip_salarizare in ('1','3') then (case when a.coeficient_acord<>0 then a.coeficient_acord when @ProcAC_regie<>0 then @ProcAC_regie/100 else 1 end) else 1 end)),0), 
	sum(a.Ore_acord), round(sum(a.realizat*(case when a.tip_salarizare='5' and @CorL_SREAC=1 then isnull(s.Procent_corectie,100)/100.00 else 1 end)-
		(case when @Indspl_acordind=1 and a.tip_salarizare='4' 
			then (a.ore_suplimentare_1*@ProcOS1/100+a.ore_suplimentare_2*@ProcOS2/100+a.ore_suplimentare_3*@ProcOS3/100+a.ore_suplimentare_4*@ProcOS4/100)*c.salar_orar else 0 end)),0), 
	sum(a.Ore_suplimentare_1), 
	round(sum(a.Ore_suplimentare_1*(case when @OS1_OreM=1 then (case when @Buget=1 then b.salar_de_baza else b.salar_de_incadrare end)/@OreM_luna else c.salar_orar end)*@ProcOS1/100),0), 
	sum(a.Ore_suplimentare_2), 
	round(sum(a.Ore_suplimentare_2*(case when @OS2_OreM=1 then (case when @Buget=1 then b.salar_de_baza else b.salar_de_incadrare end)/@OreM_luna else c.salar_orar end)*@ProcOS2/100),0), 
	sum(a.Ore_suplimentare_3), 
	round(sum(a.Ore_suplimentare_3*c.salar_orar*@ProcOS3/100),0),sum(a.Ore_suplimentare_4), round(sum(a.Ore_suplimentare_4*c.salar_orar*@ProcOS4/100),0), 
	sum(a.Ore_spor_100), (case when @O100_Find=1 then 0 else 1 end)*round(sum(a.Ore_spor_100* c.salar_orar),0), 
	sum(a.Ore_de_noapte), round(sum(round(a.Ore_de_noapte*c.salar_orar,2)*b.spor_de_noapte/100),0), 
--	ore/indemnizatie regim normal
	sum(case when @Somesana=1 and 1=0 
		then (@Ore_luna/8)*a.regim_de_lucru
			-(a.Ore_intrerupere_tehnologica+a.Ore+a.Ore_obligatii_cetatenesti+a.Ore_concediu_fara_salar+a.Ore_concediu_de_odihna+a.Ore_concediu_medical+a.Ore_invoiri+a.Ore_nemotivate) 
		else (case when @Somesana=1 then 0 else a.ore_acord end)+a.ore_regie+@ScadOS_RN*(a.ore_suplimentare_1+@ORegieFaraOS2*a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4)
			+@ScadO100_RN*a.ore_spor_100+@Salubris*(a.ore_suplimentare_1+a.ore_suplimentare_2-a.ore_suplimentare_3)
			+(case when @Adun_OIT_RN=1 then a.ore_intrerupere_tehnologica+(case when @Colas=1 then a.Spor_cond_8 else 0 /*(case when @SomajTehnic=1 then 0 else a.ore end)*/ end) else 0 end) end), 
	round(sum((case when @Somesana=1 and 1=0 
		then (@Ore_luna/8)*a.regim_de_lucru
			-(a.Ore_intrerupere_tehnologica+a.Ore+a.Ore_obligatii_cetatenesti+a.Ore_concediu_fara_salar+a.Ore_concediu_de_odihna+a.Ore_concediu_medical+a.Ore_invoiri+a.Ore_nemotivate) 
		else (case when @Somesana=1 then 0 else a.ore_acord end)+a.ore_regie+@ScadOS_RN*(a.ore_suplimentare_1+@ORegieFaraOS2*a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4)
			+@ScadO100_RN*a.ore_spor_100+@Salubris*(a.ore_suplimentare_1+a.ore_suplimentare_2-a.ore_suplimentare_3)
			+(case when @Adun_OIT_RN=1 then a.ore_intrerupere_tehnologica+(case when @Colas=1 then a.spor_cond_8 else 0 /*(case when @SomajTehnic=1 then 0 else a.ore end)*/ end) 
				else 0 end) end)*c.salar_orar),0), 
	sum(a.Ore_intrerupere_tehnologica+@Elite*a.Ore),round(sum(a.ore_intrerupere_tehnologica*c.salar_orar*@ProcIT1/100),0),
	sum(a.Ore_obligatii_cetatenesti), round(sum((case when @COEV_macheta=1 then 0 
		else c.salar_orar* (1+@Acumulato*b.spor_vechime/100+@Salubris*(b.spor_de_functie_suplimentara+b.spor_conditii_6)/100)*a.ore_obligatii_cetatenesti end)),0), 
	sum(a.Ore_concediu_fara_salar),0, sum(a.Ore_concediu_de_odihna),0,sum(a.Ore_concediu_medical),0,0,sum(a.Ore_invoiri), 
	sum(case when @Drumco=1 then a.ore*a.Coeficient_de_timp else a.ore*c.salar_orar*@ProcIT2/100 end) as Ind_invoiri,
	sum(a.Ore_nemotivate),0,round(sum((case when a.tip_salarizare<'5' then 0 else (case when @Dafora=1 and a.tip_salarizare='6' and abs(a.salar_categoria_lucrarii-@Salar_min/@Ore_luna)<1 
		then a.ore_regie*@Salar_min/@Ore_luna else a.ore_regie*a.salar_categoria_lucrarii*(case when @Indicip_lm=1 and a.coeficient_acord<>0 then a.coeficient_acord else 1 end) end) end)),0), 
	0,0,0,0,0,0,0,0,0,0,0,0,0,round(sum(a.sistematic_peste_program*(case when a.ore_sistematic_peste_program>0 then a.ore_sistematic_peste_program 
		else (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100) end)* c.salar_orar/100),0), 0, 
--	spor specific
	round((case when @Anul_spv_1zinem=1 and sum(a.Ore_nemotivate)>7 then 0 
		else sum(case when @Buget=1 then (b.salar_de_incadrare+(case when @Indc_Spsp=1 then (case when @Indc_suma=1 then b.Indemnizatia_de_conducere 
			else round(b.salar_de_incadrare*b.Indemnizatia_de_conducere/100,0) end) else 0 end))*(case when @Spsp_oreRN=1 
				then (a.ore_acord+a.ore_regie+@ScadOS_RN*(a.ore_suplimentare_1+@ORegieFaraOS2*a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4))/
					(convert(float,@Ore_luna)/8*c.regim_de_lucru) else 1 end)*b.Spor_specific/100 when @Spsp_suma=1 then a.spor_specific else 
		(case when @Dafora=1 then b.Spor_specific else (case when @Spsp_proc_unit=1 and (@Eurosimex=0 or a.tip_salarizare<>'4') then @Proc_Spsp else a.spor_specific end) end)/100*
			(case when @Spsp_proc_suma=1 then @Baza_Spsp else round((a.ore_acord+a.ore_regie+(case when @Drumco=1 or @Dafora=1 or @Spsp_oreRN=1 
				then @ScadOS_RN*(a.ore_suplimentare_1+@ORegieFaraOS2*a.ore_suplimentare_2+a.ore_suplimentare_3+a.ore_suplimentare_4)+@ScadO100_RN*a.ore_spor_100 
				else a.ore_intrerupere_tehnologica*@ProcIT1/100 end))*(case when @Spsp_salim=1 and a.tip_salarizare>='3' then b.salar_de_incadrare/@Ore_luna else c.salar_orar end),0) end) end) end),0),
--	spor conditii
	round(convert(decimal(12,2),sum(case when @SpCond1OL=1 and a.Ore__cond_1=0 and @SpCondOL=0 or @DSVET=1 then 0 when @Sp1_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_1 
		when @Sp1_suma=1 and @Sp1_sumazi=1 then a.spor_conditii_1*(case when a.Ore__cond_1>0 then a.Ore__cond_1/c.regim_de_lucru 
			else convert(int,(ore_acord+ore_regie+@ScadOS_RN*(ore_suplimentare_1+@ORegieFaraOS2*ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4)+@ScadO100_RN*ore_spor_100)/c.regim_de_lucru) end) 
		when @Sp1_suma=1 then a.spor_conditii_1*(case when Ore__cond_1=0 and @Drumor=1 or @Drumco=1 then (@Ore_luna/8*c.regim_de_lucru) 
			when Ore__cond_1=0 then @Sp1_oreg*a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100 else Ore__cond_1 end)/(@Ore_luna/8*c.regim_de_lucru) 
		else a.spor_conditii_1/100*(case when a.Ore__cond_1>0 then a.Ore__cond_1 else (@Sp1_oreg*a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100) end)
			*(case when @Plata_ora=1 and b.salar_lunar_de_baza<>0 then b.salar_lunar_de_baza/@Ore_luna else c.salar_orar end) end)),0),
	round(convert(decimal(12,2),sum(case when @SpCond2OL=1 and a.Ore__cond_2=0 and @SpCondOL=0 or @Gencom=1 then 0 when @Sp2_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_2 
		when @Sp2_suma=1 then a.spor_conditii_2*(case when Ore__cond_2=0 and @Drumor=1 or @Drumco=1 then (@Ore_luna/8*c.regim_de_lucru) 
			when Ore__cond_2=0 then (a.ore_acord+@Sp2_oreac*a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+(case when @Pasmatex=1 then a.ore_concediu_de_odihna else 0 end)) 
				else Ore__cond_2 end)/(@Ore_luna/8*c.regim_de_lucru) 
		else a.spor_conditii_2/100*(case when a.Ore__cond_2>0 then a.Ore__cond_2 
			else (a.ore_acord+@Sp2_oreac*a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+(case when @Pasmatex=1 then a.ore_concediu_de_odihna else 0 end)+@Spc_O100*a.ore_spor_100) end)*c.salar_orar end)),0),
	round(convert(decimal(12,2),sum(case when @SpCond3OL=1 and a.Ore__cond_3=0 and @SpCondOL=0 then 0 when @Sp3_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_3 
		when @Sp3_suma=1 then a.spor_conditii_3*(case when Ore__cond_3=0 and @Drumor=1 or @Drumco=1 then (@Ore_luna/8*c.regim_de_lucru) 
			when Ore__cond_3=0 then a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100 else Ore__cond_3 end)/(@Ore_luna/8*c.regim_de_lucru) 
		else a.spor_conditii_3/100*(case when a.Ore__cond_3>0 then a.Ore__cond_3 
			else (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100) end)*c.salar_orar end)),0),
	round(convert(decimal(12,2),sum(case when @SpCond4OL=1 and a.Ore__cond_4=0 and @SpCondOL=0 then 0 when @Sp4_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_4 
		when @Sp4_suma=1 then a.spor_conditii_4*(case when Ore__cond_4=0 and @Drumor=1 or @Drumco=1 then (@Ore_luna/8*c.regim_de_lucru) 
			when Ore__cond_4=0 then a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100 else Ore__cond_4 end)/(@Ore_luna/8*c.regim_de_lucru) 
		else a.spor_conditii_4/100*(case when a.Ore__cond_4>0 then a.Ore__cond_4 else (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100) end)*c.salar_orar end)),0),
	round(convert(decimal(12,2),sum(case when @SpCond5OL=1 and a.Ore__cond_5=0 and @SpCondOL=0 then 0 when @Sp5_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_5 
		when @Sp5_suma=1 then a.spor_conditii_5*(case when Ore__cond_5=0 and @Drumor=1 or @Drumco=1 then (@Ore_luna/8*c.regim_de_lucru) 
			when Ore__cond_5=0 then a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100 else Ore__cond_5 end)/(@Ore_luna/8*c.regim_de_lucru) 
		else a.spor_conditii_5/100*(case when a.Ore__cond_5>0 then a.Ore__cond_5 else (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100) end)*c.salar_orar end)),0),
	round(convert(decimal(12,2),sum(case when @SpCond6OL=1 and a.Ore_donare_sange=0 and @SpCondOL=0 then 0 when @Sp6_suma=1 and @Spc_sumafixa=1 then a.spor_conditii_6 
		when @Sp6_suma=1 then a.spor_conditii_6*(case when Ore_donare_sange=0 and @Drumor=1 or @Drumco=1 then ((case when a.tip_salarizare<3 then @Ore_luna else @OreM_luna end)/8*c.regim_de_lucru) 
			when Ore_donare_sange=0 then a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100 else Ore_donare_sange end)/
				((case when a.tip_salarizare<3 or @Sp6_oreluna=1 then @Ore_luna else @OreM_luna end)/8*c.regim_de_lucru) 
		else a.spor_conditii_6/100*(case when @Sp6_procsuma=1 then @Suma_bazasp6*convert(int,(a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+
			@ARLCJ*(@ScadOS_RN*(ore_suplimentare_1+@ORegieFaraOS2*ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4)+@ScadO100_RN*ore_spor_100))/c.regim_de_lucru)/
				((case when a.tip_salarizare<3 or @Sp6_oreluna=1 then @Ore_luna else @OreM_luna end)/8) 
				else (case when a.Ore_donare_sange>0 then a.Ore_donare_sange 
					else (a.ore_acord+a.ore_regie+a.ore_intrerupere_tehnologica*@NuSpc_OIT/100+@Spc_O100*a.ore_spor_100+@Salubris*(ore_suplimentare_1+ore_suplimentare_2-ore_suplimentare_3)) end)*c.salar_orar end) end)),0),
	0,0,max(c.salar_orar),0,0,0,0,0,0,max(c.regim_de_lucru)
	from pontaj a 
		left outer join curscor s on @CorL_SREAC=1 and s.data between @dataJos and @dataSus and a.marca=s.marca and s.tip_corectie_venit='L-' and a.loc_de_munca=s.loc_de_munca
		,personal b, #salor c 
	where a.data between @dataJos and @dataSus and a.marca=b.marca and a.Data=c.Data 
		and a.marca=c.marca and a.marca between @MarcaJos and @MarcaSus and a.loc_de_munca=c.loc_de_munca 
--		24.09.2012 - am tratat sa faca filtrarea functie de locul de munca din personal (in loc de pontaj) pt. a efectua calcul complet pe o marca la filtru pe loc de munca.
--		and a.loc_de_munca between @LocmJos and @LocmSus
		and b.loc_de_munca between @LocmJos and @LocmSus and a.numar_curent=c.numar_curent 
	group by a.marca,a.loc_de_munca
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura pInsert_brut (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
