--***
/**	procedura pentru recalcul sporuri	*/
Create procedure pRecalcul_sporuri
	@dataJos datetime, @dataSus datetime, @MarcaJos char(6), @MarcaSus char(6), @LocmJos char(9), @LocmSus char(9) 
As
Begin try
	declare @Ore_luna float, @OreM_luna float, @Ore_luna_tura float, @Suma_comp float, @MachetaCO int, @CO_pontaj int, 
	@Anul_spv_1zinem int, @Anul_spv_Xzinem int, @Zile_anulare_spv int, 
	@Spv_CO int,@Spfs_CO int, @Spsp_CO int, @Spspp_CO int, @Indc_CO int, @Sp1_CO int,@Sp2_CO int,@Sp3_CO int, @Sp4_CO int,@Sp5_CO int,@Sp6_CO int,@Sp7_CO int, @Comp_CO int,
	@Spsp_suma int, @Sp1_suma int,@Sp2_suma int,@Sp3_suma int, @Sp4_suma int,@Sp5_suma int, @Sp6_suma int,@Spfs_suma int, @Indc_suma int, @lProcfix_co int,@nProcfix_co float, 
	@Spsp_proc_suma int, @Baza_Spsp float, @Spsp_pers int, @Spsp_co_baza_suma int, @Spsp_co_nu_baza_suma int, @nButon_calcul int, @Zile_calcul_co float, 
	@dataJos_CO datetime, @dataSus_CO datetime,@Spv_oreCO int,@Spv_oreOBL int,@Spv_oreINT int,@Spv_Indc int,@Indc_FORE int,@Buget int,@RegimLV int, 
	@Dafora int, @Elcond int, @Drumor int, @Samobil int, @Salubris int

--	parametrii lunari
	set @Ore_luna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @OreM_luna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
	set @Ore_luna_tura=dbo.iauParLN(@dataSus,'PS','ORET_LUNA')
	if @Ore_luna_tura=0 set @Ore_luna_tura=dbo.iauParN('PS','ORET_LUNA')
--	parametrii 
	select @Spv_co=max(case when parametru='CO-SP-V' then Val_logica else 0 end),
		@Spfs_co=max(case when parametru='CO-F-SPL' then Val_logica else 0 end),
		@Spsp_co=max(case when parametru='CO-SPEC' then Val_logica else 0 end),
		@Spspp_co=max(case when parametru='CO-S-PR' then Val_logica else 0 end),
		@Indc_co=max(case when parametru='CO-IND' then Val_logica else 0 end),
		@Sp1_co=max(case when parametru='CO-SP1' then Val_logica else 0 end),
		@Sp2_CO=max(case when parametru='CO-SP2' then Val_logica else 0 end),
		@Sp3_CO=max(case when parametru='CO-SP3' then Val_logica else 0 end),
		@Sp4_CO=max(case when parametru='CO-SP4' then Val_logica else 0 end),
		@Sp5_CO=max(case when parametru='CO-SP5' then Val_logica else 0 end),
		@Sp6_CO=max(case when parametru='CO-SP6' then Val_logica else 0 end),
		@Sp7_CO=max(case when parametru='CO-SP7' then Val_logica else 0 end),
		@Comp_CO=max(case when parametru='CO-COMP' then Val_logica else 0 end),
		@Suma_comp=max(case when parametru='SUMACOMP' then Val_numerica else 0 end),
		@Spsp_suma=max(case when parametru='SSP-SUMA' then Val_logica else 0 end),
		@Sp1_suma=max(case when parametru='SC1-SUMA' then Val_logica else 0 end),
		@Sp2_suma=max(case when parametru='SC2-SUMA' then Val_logica else 0 end),
		@Sp3_suma=max(case when parametru='SC3-SUMA' then Val_logica else 0 end),
		@Sp4_suma=max(case when parametru='SC4-SUMA' then Val_logica else 0 end),
		@Sp5_suma=max(case when parametru='SC5-SUMA' then Val_logica else 0 end),
		@Sp6_suma=max(case when parametru='SC6-SUMA' then Val_logica else 0 end),
		@Spfs_suma=max(case when parametru='SPFS-SUMA' then Val_logica else 0 end),
		@Indc_suma=max(case when parametru='INDC-SUMA' then Val_logica else 0 end),
		@lProcfix_co=max(case when parametru='CO-SPFIX' then Val_logica else 0 end),
		@nProcfix_co=max(case when parametru='CO-SPFIX' then Val_numerica else 0 end),
		@Spsp_proc_suma=max(case when parametru='SSPEC' then Val_logica else 0 end),
		@Baza_Spsp=max(case when parametru='SSPEC' then Val_numerica else 0 end),
		@nButon_calcul=max(case when parametru='CALCUL-CO' then Val_numerica else 0 end),
		@Zile_calcul_co=max(case when parametru='CO-NRZILE' then Val_numerica else 0 end),
		@Anul_spv_1zinem=max(case when parametru='SP-V-ANUL' then Val_logica else 0 end),
		@Anul_spv_Xzinem=max(case when parametru='SP-V-ANZI' then Val_logica else 0 end),
		@Zile_anulare_spv=max(case when parametru='SP-V-ANZI' then Val_numerica else 0 end),
		@Spv_oreCO=max(case when parametru='SP-V-OCO' then Val_logica else 0 end),
		@Spv_oreOBL=max(case when parametru='SP-V-OOBL' then Val_logica else 0 end),
		@Spv_oreINT=max(case when parametru='SP-V-OINT' then Val_logica else 0 end),
		@Spv_Indc=max(case when parametru='SP-V-INDC' then Val_logica else 0 end),
		@CO_pontaj=max(case when parametru='CO-NR-ORE' then Val_logica else 0 end),
		@Indc_FORE=max(case when parametru='IND-FORE' then Val_logica else 0 end),
		@MachetaCO=max(case when parametru='OPZILECOM' then Val_logica else 0 end),
		@Buget=max(case when parametru='UNITBUGET' then Val_logica else 0 end),
		@RegimLV=max(case when parametru='REGIMLV' then Val_logica else 0 end),		
		@Dafora=max(case when parametru='DAFORA' then Val_logica else 0 end),
		@Elcond=max(case when parametru='ELCOND' then Val_logica else 0 end),
		@Drumor=max(case when parametru='DRUMOR' then Val_logica else 0 end),
		@Samobil=max(case when parametru='SAMOBIL' then Val_logica else 0 end),
		@Salubris=max(case when parametru='SALUBRIS' then Val_logica else 0 end)
	from par where tip_parametru in ('PS','SP') 
		and parametru in ('CO-SP-V','CO-F-SPL','CO-SPEC','CO-S-PR','CO-IND','CO-SP1','CO-SP2','CO-SP3','CO-SP4','CO-SP5','CO-SP6','CO-SP7','CO-COMP','SUMACOMP',
			'SSP-SUMA','SC1-SUMA','SC2-SUMA','SC3-SUMA','SC4-SUMA','SC5-SUMA','SC6-SUMA','SPFS-SUMA','INDC-SUMA','CO-SPFIX','SSPEC','CALCUL-CO','CO-NRZILE',
			'SP-V-ANUL','SP-V-ANZI','SP-V-OCO','SP-V-OOBL','SP-V-OINT','SP-V-INDC','CO-NR-ORE','IND-FORE','OPZILECOM',
			'UNITBUGET','REGIMLV','DAFORA','ELCOND','DRUMOR','SAMOBIL','SALUBRIS')

	set @dataJos_CO=dbo.eom(dateadd(month,-3,@dataJos))
	set @dataSus_CO=dbo.eom(dateadd(month,-1,@dataJos))
	set @Spsp_pers=(case when @Spsp_co=1 and @Spsp_proc_suma=0 and @Spsp_suma=0 then 1 else 0 end)
	set @Spsp_co_baza_suma=(case when @Spsp_co=1 and @Spsp_proc_suma=1 then 1 else 0 end)
	set @Spsp_co_nu_baza_suma=(case when @Spsp_co=1 and @Spsp_proc_suma=0 then 1 else 0 end)

	update brut set 
	realizat__regie=(case when abs((case when @Buget=1 then p.salar_de_baza else p.salar_de_incadrare end)-realizat__regie)<=0.05 
		then (case when @Buget=1 then p.salar_de_baza else p.salar_de_incadrare end) else realizat__regie end), 
	spor_vechime=round((case when @Anul_spv_1zinem=1 and ore_nemotivate>7 
		or @Anul_spv_Xzinem=1 and isnull((select sum(p.Coeficient_de_timp) from pontaj p where p.data between @dataJos and @dataSus and p.marca=p.marca),0)>=@Zile_anulare_spv 
		then 0 else round(p.spor_vechime/100*round(convert(decimal(12,2),(case when @Drumor=1 or @Buget=1 and @Salubris=0 
		then (case when ore_lucrate_regim_normal>=@Ore_luna and @Drumor=1 then p.salar_de_incadrare 
			else convert(float,ore_lucrate_regim_normal+@Spv_oreOBL*brut.ore_obligatii_cetatenesti+@Spv_oreINT*brut.ore_intrerupere_tehnologica)*brut.salar_orar end) 
		else ind_regim_normal+@Spv_Indc*p.indemnizatia_de_conducere*(case when @Indc_suma=0 then p.salar_de_incadrare/100 else 1 end)
			*(case when brut.ore_lucrate_regim_normal>@Ore_luna or @Indc_FORE=1 then 1 else brut.ore_lucrate_regim_normal/convert(float,@Ore_luna) end)
		+@Spv_oreOBL*brut.ore_obligatii_cetatenesti*brut.salar_orar+@Spv_oreINT*brut.ore_intrerupere_tehnologica*brut.salar_orar+@Samobil*brut.ore_suplimentare_3*brut.salar_orar
		+@Spv_oreCO*(case when @MachetaCO=1 then brut.ind_concediu_de_odihna  when @CO_pontaj=0 then 0 else ore_concediu_de_odihna/
		(case  when @Ore_luna_tura<>0 and p.salar_lunar_de_baza<>0 then @Ore_luna_tura when @nButon_calcul=4 and p.tip_salarizare in ('1','2') or @nButon_calcul=2 
		then @Ore_luna when @nButon_calcul=4 and p.tip_salarizare not in ('1','2') or @nButon_calcul=3 then @OreM_luna else 8*@Zile_calcul_co end)/
		(case when @Dafora=1 then 8 else brut.spor_cond_10 end)*8*(p.salar_de_incadrare*(100 +@Spv_co*p.spor_vechime+@Spfs_co*(case when @Spfs_suma=1 then 0 else p.spor_de_functie_suplimentara end)
		+@Spsp_pers*p.spor_specific+@Spspp_co*p.spor_sistematic_peste_program+@Sp1_co*(case when @Sp1_suma=1 then 0 else p.spor_conditii_1 end)
		+@Sp2_co*(case when @Sp2_suma=1 then 0 else p.spor_conditii_2 end)+@Sp3_co*(case when @Sp3_suma=1 then 0 else p.spor_conditii_3 end)
		+@Sp4_co*(case when @Sp4_suma=1 then 0 else p.spor_conditii_4 end)+@Sp5_co*(case when @Sp5_suma=1 then 0 else p.spor_conditii_5 end)
		+@Sp6_co*(case when @Sp6_suma=1 then 0 else p.spor_conditii_6 end))/100+ @Spsp_co_baza_suma*@Baza_Spsp*p.spor_specific/100+@Indc_co*p.indemnizatia_de_conducere
		+@Comp_CO*@Suma_comp+@Spfs_co*(case when @Spfs_suma=1 then p.spor_de_functie_suplimentara else 0 end)+@Sp1_co*(case when @Sp1_suma=1 then p.spor_conditii_1 else 0 end)
		+@Sp2_co*(case when @Sp2_suma=1 then p.spor_conditii_2 else 0 end)+@Sp3_co*(case when @Sp3_suma=1 then p.spor_conditii_3 else 0 end)
		+@Sp4_co*(case when @Sp4_suma=1 then p.spor_conditii_4 else 0 end)+@Sp5_co*(case when @Sp5_suma=1 then p.spor_conditii_5 else 0 end)
		+@Sp6_co*(case when @Sp6_suma=1 then p.spor_conditii_6 else 0 end)) end) end)),0),0) end),0), 
	spor_de_functie_suplimentara=(case when @Spfs_suma=1 then p.spor_de_functie_suplimentara else round(p.spor_de_functie_suplimentara*ind_regim_normal/100,0) end), 
	ind_concediu_de_odihna=(case when @CO_pontaj=0 or @MachetaCO=1 then 0 
		else round(convert(decimal(15,5),ore_concediu_de_odihna/(case when @RegimLV=1 and @Ore_luna_tura<>0 and p.salar_lunar_de_baza<>0 then @Ore_luna_tura 
			when @nButon_calcul=4 and p.tip_salarizare in ('1','2') or @nButon_calcul=2 then @Ore_luna 
			when @nButon_calcul=4 and p.tip_salarizare not in ('1','2') or @nButon_calcul=3 then @OreM_luna else 8*@Zile_calcul_co end)/
		(case when @Dafora=1 then 8 else brut.spor_cond_10 end)*8*((case when @Buget=1 then p.salar_de_baza else p.salar_de_incadrare end)*
		(100 +@Spv_co*p.spor_vechime+@Spfs_co*(case when @Spfs_suma=1 then 0 else p.spor_de_functie_suplimentara end)+@Spsp_pers*p.spor_specific
		+@Spspp_co*p.spor_sistematic_peste_program+@Sp1_co*(case when @Sp1_suma=1 then 0 else p.spor_conditii_1 end)
		+@Sp2_co*(case when @Sp2_suma=1 then 0 else p.spor_conditii_2 end)+@Sp3_co*(case when @Sp3_suma=1 then 0 else p.spor_conditii_3 end)
		+@Sp4_co*(case when @Sp4_suma=1 then 0 else p.spor_conditii_4 end)+@Sp5_co*(case when @Sp5_suma=1 then 0 else p.spor_conditii_5 end)
		+@Sp6_co*(case when @Sp6_suma=1 then 0 else p.spor_conditii_6 end)+@Sp7_co*isnull(c.spor_cond_7,0)
		+(case when @Indc_suma=0 then @Indc_co*p.indemnizatia_de_conducere else 0 end)+@lProcfix_co*@nProcfix_co)/100
		+@Spsp_co_baza_suma*@Baza_Spsp*p.spor_specific/100+@Spsp_co_nu_baza_suma*(case when @Spsp_suma=1 then p.spor_specific else 0 end)
		+@Spv_co*p.spor_vechime/100*@Spv_Indc*p.indemnizatia_de_conducere*(case when @Indc_suma=0 then p.salar_de_incadrare/100 else 1 end)
		+(case when @Indc_suma=1 then @Indc_co*p.indemnizatia_de_conducere else 0 end)+@Suma_comp
		+@Spfs_co*(case when @Spfs_suma=1 then p.spor_de_functie_suplimentara else 0 end)
		+@Sp1_co*(case when @Sp1_suma=1 then p.spor_conditii_1 else 0 end)+@Sp2_co*(case when @Sp2_suma=1 then p.spor_conditii_2 else 0 end)
		+@Sp3_co*(case when @Sp3_suma=1 then p.spor_conditii_3 else 0 end)+ @Sp4_co*(case when @Sp4_suma=1 then p.spor_conditii_4 else 0 end)
		+@Sp5_co*(case when @Sp5_suma=1 then p.spor_conditii_5 else 0 end)+@Sp6_co*(case when @Sp6_suma=1 then p.spor_conditii_6 else 0 end))),0) end), 
	compensatie=@Suma_comp*(ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_concediu_medical)/@Ore_luna 
	from personal p 
		left outer join infopers c on c.marca = p.marca
	where brut.data between @dataJos and @dataSus  and brut.marca between @MarcaJos and @MarcaSus 
		and brut.marca=p.marca 
--		and brut.loc_de_munca between @LocmJos and @LocmSus 
		and p.loc_de_munca between @LocmJos and @LocmSus 

	if @MachetaCO=1
		exec scriu_brut_din_CO @dataJos, @dataSus, @MarcaJos, @LocmJos
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura pRecalcul_sporuri (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
