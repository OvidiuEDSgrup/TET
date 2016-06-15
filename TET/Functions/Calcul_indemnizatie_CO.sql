--***
/**	functie calcul indemniz. CO	*/
Create function Calcul_indemnizatie_CO
	(@dataJos datetime, @dataSus datetime, @Data_CO datetime, @Marca char(6), @Tip_concediu char(1), @Zile_CO int, @Regim_lucru float, @Data_inceput datetime, @Data_sfarsit datetime)
Returns float
As
Begin
	declare @COEV_macheta int, @OUG65 int, @OUG65_SI varchar(200), @CO_MVB int, @Nr_luni_MVB int, @Spv_co int,@Spfs_co int,@Spspec_co int,@Spspp_co int, @Indcond_co int, 
	@Sp1_co int,@Sp2_co int,@Sp3_co int, @Sp4_co int,@Sp5_co int,@Sp6_co int,@Sp7_co int, 
	@Spspec_suma int, @Sp1_suma int,@Sp2_suma int,@Sp3_suma int, @Sp4_suma int,@Sp5_suma int, @Sp6_suma int, @Spfs_suma int,@Indcond_suma int, 
	@lProcfix_co int,@nProcfix_co float, @Suma_comp_co int,@Comp_co int, @Suma_comp float, @Spv_indcond int,
	@nOre_luna int,@nOre_luna_tura int, @Nrm_ore_luna int, @nButon_calcul int,@Zile_calcul_co float,@Ore_calcul_co float,
	@lRegimLV int, @lBuget int, @Spspec_proc_suma int, @Baza_spspec float, @Spspec_pers int, @Spspec_co_baza_suma int, @Spspec_co_nu_baza_suma int, 
	@Data1 datetime, @Data2 datetime, @Medie_zilnica float, @Indemnizatie_CO float, @ExistaModifSalarLuna int, @DataModifSalar datetime, 
	@SpElcond int, @SpDafora int, @Salubris int, @Remarul int
	
	set @Data1=dbo.eom(dateadd(month,(case when @CO_MVB=1 then @Nr_luni_MVB else -3 end),@dataJos))
	set @Data2=dbo.eom(dateadd(month,-1,@dataJos))

	set @nOre_luna=dbo.iauParLN(@Data_CO,'PS','ORE_LUNA')
	if @nOre_luna=0
		set @nOre_luna=dbo.Zile_lucratoare(dbo.bom(@Data_CO),@Data_CO)*8
	set @nOre_luna_tura=dbo.iauParLN(@Data_CO,'PS','ORET_LUNA')
	if @nOre_luna_tura=0
		set @nOre_luna_tura=dbo.iauParN('PS','ORET_LUNA')
	set @Nrm_ore_luna=dbo.iauParLN(@Data_CO,'PS','NRMEDOL')
	if @Nrm_ore_luna=0
		set @Nrm_ore_luna=dbo.iauParN('PS','NRMEDOL') 

	select @COEV_macheta=max(case when parametru='COEVMCO' then Val_logica else 0 end), 
		@OUG65=max(case when parametru='CO-OUG65' then Val_logica else 0 end),
		@OUG65_SI=max(case when parametru='CO-OUG65' then Val_alfanumerica else '' end),	--	calcul medie pe ultimele 3 luni functie de salariile de baza+sporuri
		@CO_MVB=max(case when parametru='MEDVB_CO' then Val_logica else 0 end),
		@Nr_luni_MVB=max(case when parametru='MEDVB_CO' then Val_numerica else 0 end),
		@Spv_co=max(case when parametru='CO-SP-V' then Val_logica else 0 end),
		@Spfs_co=max(case when parametru='CO-F-SPL' then Val_logica else 0 end),
		@Spspec_co=max(case when parametru='CO-SPEC' then Val_logica else 0 end),
		@Spspp_co=max(case when parametru='CO-S-PR' then Val_logica else 0 end),
		@Indcond_co=max(case when parametru='CO-IND' then Val_logica else 0 end),
		@Sp1_co=max(case when parametru='CO-SP1' then Val_logica else 0 end),
		@Sp2_co=max(case when parametru='CO-SP2' then Val_logica else 0 end),
		@Sp3_co=max(case when parametru='CO-SP3' then Val_logica else 0 end),
		@Sp4_co=max(case when parametru='CO-SP4' then Val_logica else 0 end),
		@Sp5_co=max(case when parametru='CO-SP5' then Val_logica else 0 end),
		@Sp6_co=max(case when parametru='CO-SP6' then Val_logica else 0 end),
		@Sp7_co=max(case when parametru='CO-SP7' then Val_logica else 0 end),
		@Spspec_suma=max(case when parametru='SSP-SUMA' then Val_logica else 0 end),
		@Sp1_suma=max(case when parametru='SC1-SUMA' then Val_logica else 0 end),
		@Sp2_suma=max(case when parametru='SC2-SUMA' then Val_logica else 0 end),
		@Sp3_suma=max(case when parametru='SC3-SUMA' then Val_logica else 0 end),
		@Sp4_suma=max(case when parametru='SC4-SUMA' then Val_logica else 0 end),
		@Sp5_suma=max(case when parametru='SC5-SUMA' then Val_logica else 0 end),
		@Sp6_suma=max(case when parametru='SC6-SUMA' then Val_logica else 0 end),
		@Spfs_suma=max(case when parametru='SPFS-SUMA' then Val_logica else 0 end),
		@Indcond_suma=max(case when parametru='INDC-SUMA' then Val_logica else 0 end),
		@lProcfix_co=max(case when parametru='CO-SPFIX' then Val_logica else 0 end),
		@nProcfix_co=max(case when parametru='CO-SPFIX' then Val_numerica else 0 end),
		@Comp_co=max(case when parametru='CO-COMP' then Val_logica else 0 end),
		@Suma_comp=max(case when parametru='SUMACOMP' then Val_numerica else 0 end),
		@Spv_indcond=max(case when parametru='SP-V-INDC' then Val_logica else 0 end),
		@nButon_calcul=max(case when parametru='CALCUL-CO' then Val_numerica else 0 end),
		@Zile_calcul_co=max(case when parametru='CO-NRZILE' then Val_numerica else 0 end),
		@Spspec_proc_suma=max(case when parametru='SSPEC' then Val_logica else 0 end),
		@Baza_spspec=max(case when parametru='SSPEC' then Val_numerica else 0 end),
		@lRegimLV=max(case when parametru='REGIMLV' then Val_logica else 0 end),
		@lBuget=max(case when parametru='UNITBUGET' then Val_logica else 0 end),
		@Salubris=max(case when tip_parametru='SP' and parametru='SALUBRIS' then Val_logica else 0 end),
		@SpElcond=max(case when tip_parametru='SP' and parametru='ELCOND' then Val_logica else 0 end),
		@SpDafora=max(case when tip_parametru='SP' and parametru='DAFORA' then Val_logica else 0 end),
		@Remarul=max(case when tip_parametru='SP' and parametru='REMARUL' then Val_logica else 0 end)
	from par where tip_parametru in ('PS','SP') 
		and parametru in ('COEVMCO','CO-OUG65','MEDVB_CO','CO-SP-V','CO-F-SPL','CO-SPEC','CO-S-PR','CO-IND',
			'CO-SP1','CO-SP2','CO-SP3','CO-SP4','CO-SP5','CO-SP6','CO-SP7','SSP-SUMA','SC1-SUMA','SC2-SUMA','SC3-SUMA','SC4-SUMA','SC5-SUMA','SC6-SUMA',
			'SPFS-SUMA','INDC-SUMA','CO-SPFIX','CO-COMP','SUMACOMP','SP-V-INDC','CALCUL-CO','CO-NRZILE','SSPEC',
			'REGIMLV','UNITBUGET','SALUBRIS','ELCOND','DAFORA','REMARUL')

	select @Suma_comp=(case when @Comp_co=1 then @Suma_comp else 0 end),
		@Ore_calcul_co=(case when @nButon_calcul=1 then 8*@Zile_calcul_co when @nButon_calcul=2 then @nOre_luna else @Nrm_ore_luna end),
		@Spspec_pers=(case when @Spspec_co=1 and @Spspec_proc_suma=0 and @Spspec_suma=0 then 1 else 0 end),
		@Spspec_co_baza_suma=(case when @Spspec_co=1 and @Spspec_proc_suma=1 then 1 else 0 end),
		@Spspec_co_nu_baza_suma=(case when @Spspec_co=1 and @Spspec_proc_suma=0 then 1 else 0 end)

--	creez tabela temporara pt. cazul schimbarilor de salar din cursul lunii
	declare @tmpCO table (Marca char(6), Salar_de_incadrare float, Zile_CO int)
--	verific daca exista schimbare de salar in cursul lunii
	set @DataModifSalar=isnull((select max(Data_inf) from extinfop where Marca=@marca and Cod_inf='SALAR' and Data_inf between dbo.bom(@Data_CO) and @Data_CO and Procent>1),'01/01/1901')
--	inserez salarul si zilele pt. perioada pana la schimbarea salarului
	if @DataModifSalar between dbo.bom(@Data_CO) and @Data_CO
		insert into @tmpCO (Marca, Salar_de_incadrare, Zile_CO) 
		select p.Marca, (case when day(@DataModifSalar)<>1 and (@DataModifSalar between @Data_inceput and @Data_sfarsit or @DataModifSalar>@Data_sfarsit) 
			then isnull((case when @lBuget=1 then i.Salar_de_baza else i.Salar_de_incadrare end),(case when @lBuget=1 then p.Salar_de_baza else p.Salar_de_incadrare end)) 
			else (case when @lBuget=1 then p.Salar_de_baza else p.Salar_de_incadrare end) end), 
		(case when day(@DataModifSalar)<>1 and @DataModifSalar between @Data_inceput and @Data_sfarsit then dbo.zile_lucratoare(@Data_inceput,@DataModifSalar-1) else @Zile_CO end)
		from personal p
			left outer join istPers i on i.Data=DateAdd(DAY,-1,@dataJos) and i.Marca=p.Marca
		where p.Marca=@Marca
--	inserez salarul si zilele pt. perioada de dupa schimbarea salarului
		union all
		select p.Marca, (case when @lBuget=1 then p.Salar_de_baza else p.Salar_de_incadrare end), 
		dbo.zile_lucratoare(@DataModifSalar, (case when @Data_sfarsit>@Data_CO then @Data_CO else @Data_sfarsit end))
		from personal p
		where p.Marca=@Marca and @DataModifSalar between @Data_inceput and @Data_sfarsit and day(@DataModifSalar)<>1
	else
		insert into @tmpCO (Marca, Salar_de_incadrare, Zile_CO) 
		select Marca, (case when @lBuget=1 then salar_de_baza else salar_de_incadrare end), @Zile_CO from personal where Marca=@Marca
				
--	calcul indemnizatie CO standard (functie de baza de calcul configurata)
	Select @Indemnizatie_CO=round(convert(decimal(17,5),SUM((a.Zile_CO*@Regim_lucru)/  --@Zile_CO
		(case when @lRegimLV=1 and @nOre_luna_tura<>0 and b.salar_lunar_de_baza<>0 then @nOre_luna_tura 
		when @nButon_calcul=4 and b.tip_salarizare in ('1','2') or @nButon_calcul=2 then @nOre_luna 
		when @nButon_calcul=4 and b.tip_salarizare not in ('1','2') or @nButon_calcul=3 then @Nrm_ore_luna else 8*@Zile_calcul_co end)/ 
--	scos specific Dafora in baza sesizarii 234315
		(case when @SpDafora=1 and 1=0 then 8.0 else @Regim_lucru end)*8*(a.Salar_de_incadrare*
			(100+@Spv_co*b.spor_vechime
			+@Spfs_co*(case when @Spfs_suma=1 then 0 else b.spor_de_functie_suplimentara end)
			+@Spspec_pers*b.spor_specific+@Spspp_co*b.spor_sistematic_peste_program
			+@Sp1_co*(case when @Sp1_suma=1 then 0 else b.spor_conditii_1 end) 
			+@Sp2_co*(case when @Sp2_suma=1 then 0 else b.spor_conditii_2 end)
			+@Sp3_co*(case when @Sp3_suma=1 then 0 else b.spor_conditii_3 end)
			+@Sp4_co*(case when @Sp4_suma=1 then 0 else b.spor_conditii_4 end)
			+@Sp5_co*(case when @Sp5_suma=1 then 0 else b.spor_conditii_5 end)
			+@Sp6_co*(case when @Sp6_suma=1 then 0 else b.spor_conditii_6 end)+@Sp7_co*isnull(c.spor_cond_7,0)
			+(case when @Indcond_suma=0 then @Indcond_co*b.indemnizatia_de_conducere else 0 end)
			+@lProcfix_co*@nProcfix_co)/100+@Spspec_co_baza_suma*@Baza_spspec*b.spor_specific/100
			+@Spspec_co_nu_baza_suma*(case when @Spspec_suma=1 then b.spor_specific else 0 end)
			+@Spv_co*b.spor_vechime/100*@Spv_indcond*(case when @lBuget=1 then 0 else 1 end)*b.indemnizatia_de_conducere*
				(case when @Indcond_suma=0 then b.salar_de_incadrare/100 else 1 end)
				+(case when @Indcond_suma=1 then @Indcond_co*b.indemnizatia_de_conducere else 0 end)
				+@Suma_comp+@Spfs_co*(case when @Spfs_suma=1 then b.spor_de_functie_suplimentara else 0 end)
				+@Sp1_co*(case when @Sp1_suma=1 then b.spor_conditii_1 else 0 end)
				+@Sp2_co*(case when @Sp2_suma=1 then b.spor_conditii_2 else 0 end)
				+@Sp3_co*(case when @Sp3_suma=1 then b.spor_conditii_3 else 0 end)
				+@Sp4_co*(case when @Sp4_suma=1 then b.spor_conditii_4 else 0 end)
				+@Sp5_co*(case when @Sp5_suma=1 then b.spor_conditii_5 else 0 end)
				+@Sp6_co*(case when @Sp6_suma=1 then b.spor_conditii_6 else 0 end)))),2)
	from @tmpCO a
		left outer join personal b on b.Marca=a.Marca
		left outer join infopers c on c.marca = b.marca
	where a.Marca=@Marca

--	calcul medie zilnica CO conform OUG 65/2005 (ultimele 3 luni) functie de ore lucrate in regim normal + sporuri gata calculate
	if @OUG65=1 and @Salubris=0 and @CO_MVB=0 and (@OUG65_SI='' or @OUG65_SI<>'1')
		select @Medie_zilnica=isnull((select sum(ind_regim_normal+@Spv_co*spor_vechime+@Spfs_co*spor_de_functie_suplimentara
			+round(@Spspec_co*spor_specific,0)+@Spspp_co*spor_sistematic_peste_program+@Indcond_co*ind_nemotivate
			+round(@Sp1_co*spor_cond_1,0)+round(@Sp2_co*spor_cond_2,0)+round(@Sp3_co*spor_cond_3,0)+round(@Sp4_co*spor_cond_4,0)+round(@Sp5_co*spor_cond_5,0)+round(@Sp6_co*spor_cond_6,0)+round(@Sp7_co*spor_cond_7,0)+
			ind_obligatii_cetatenesti+(case when @SpElcond=0 then ind_concediu_de_odihna else 0 end)+(case when @Remarul=1 then Ind_intrerupere_tehnologica+Ind_invoiri else 0 end))/
			(case when round(sum((ore_lucrate_regim_normal+ore_obligatii_cetatenesti+(case when @SpElcond=0 then ore_concediu_de_odihna else 0 end)+(case when @Remarul=1 then Ore_intrerupere_tehnologica else 0 end))
					/(case when old.spor_cond_10=0 then 8.00 else old.spor_cond_10 end)),0)=0 then 1 
			else round(sum((ore_lucrate_regim_normal+ore_obligatii_cetatenesti+(case when @SpElcond=0 then ore_concediu_de_odihna else 0 end)+(case when @Remarul=1 then Ore_intrerupere_tehnologica else 0 end))
			/(case when old.spor_cond_10=0 then 8.0 else old.spor_cond_10 end)),0) end) 
			from brut old where old.marca=p.marca and old.data between @Data1 and @Data2),0)
		from personal p
		where p.Marca=@Marca

--	calcul medie zilnica CO conform OUG 65/2005 (ultimele 3 luni) functie de salarul de incadrare + sporurile permanente cuvenite.
	if @OUG65=1 and @Salubris=0 and @CO_MVB=0 and @OUG65_SI='1'
		select @Medie_zilnica=isnull((select sum((old.Salar_de_incadrare*(100+@Spv_co*old.spor_vechime+@Spfs_co*(case when @Spfs_suma=1 then 0 else old.spor_de_functie_suplimentara end)
			+@Spspec_co*old.spor_specific+@Spspp_co*old.spor_sistematic_peste_program+@Indcond_co*(case when @Indcond_suma=0 then @Indcond_co*old.indemnizatia_de_conducere else 0 end)
			+@Sp1_co*(case when @Sp1_suma=1 then 0 else old.spor_conditii_1 end)+@Sp2_co*(case when @Sp2_suma=1 then 0 else old.spor_conditii_2 end)
			+@Sp3_co*(case when @Sp3_suma=1 then 0 else old.spor_conditii_3 end)+@Sp4_co*(case when @Sp4_suma=1 then 0 else old.spor_conditii_4 end)
			+@Sp5_co*(case when @Sp5_suma=1 then 0 else old.spor_conditii_5 end)+@Sp6_co*(case when @Sp6_suma=1 then 0 else old.spor_conditii_6 end)/*+@Sp7_co*ip.spor_cond_7*/+@lProcfix_co*@nProcfix_co)/100)
			+@Spspec_co_baza_suma*@Baza_spspec*old.spor_specific/100
			+@Spspec_co_nu_baza_suma*(case when @Spspec_suma=1 then old.spor_specific else 0 end)
			+@Spv_co*old.spor_vechime/100*@Spv_indcond*(case when @lBuget=1 then 0 else 1 end)*old.indemnizatia_de_conducere*
				(case when @Indcond_suma=0 then old.salar_de_incadrare/100 else 1 end)
				+(case when @Indcond_suma=1 then @Indcond_co*old.indemnizatia_de_conducere else 0 end)
				+@Suma_comp+@Spfs_co*(case when @Spfs_suma=1 then old.spor_de_functie_suplimentara else 0 end)
				+@Sp1_co*(case when @Sp1_suma=1 then old.spor_conditii_1 else 0 end)
				+@Sp2_co*(case when @Sp2_suma=1 then old.spor_conditii_2 else 0 end)
				+@Sp3_co*(case when @Sp3_suma=1 then old.spor_conditii_3 else 0 end)
				+@Sp4_co*(case when @Sp4_suma=1 then old.spor_conditii_4 else 0 end)
				+@Sp5_co*(case when @Sp5_suma=1 then old.spor_conditii_5 else 0 end)
				+@Sp6_co*(case when @Sp6_suma=1 then old.spor_conditii_6 else 0 end))/
			(sum(dbo.iauParLN(old.Data,'PS','ORE_LUNA')/8)) 
			from istpers old where old.marca=p.marca and old.data between @Data1 and @Data2),0)
		from personal p
		left outer join infopers ip on ip.marca=p.marca
		where p.Marca=@Marca

--	calcul medie zilnica specific Salubris (din istoric personal)
	if @OUG65=1 and @Salubris=1 and @CO_MVB=0
		Select @Medie_zilnica=sum(round(((case when @lBuget=1 then b.salar_de_baza else b.salar_de_incadrare end)*
			(100+@Spv_co*b.spor_vechime+@Spfs_co*(case when @Spfs_suma=1 then 0 else b.spor_de_functie_suplimentara end)
			+@Spspec_pers*b.spor_specific+@Spspp_co*b.spor_sistematic_peste_program
			+@Sp1_co*(case when @Sp1_suma=1 then 0 else b.spor_conditii_1 end) 
			+@Sp2_co*(case when @Sp2_suma=1 then 0 else b.spor_conditii_2 end)
			+@Sp3_co*(case when @Sp3_suma=1 then 0 else b.spor_conditii_3 end)
			+@Sp4_co*(case when @Sp4_suma=1 then 0 else b.spor_conditii_4 end)
			+@Sp5_co*(case when @Sp5_suma=1 then 0 else b.spor_conditii_5 end)
			+@Sp6_co*(case when @Sp6_suma=1 then 0 else b.spor_conditii_6 end)+@Sp7_co*c.spor_cond_7
			+(case when @Indcond_suma=0 then @Indcond_co*b.indemnizatia_de_conducere else 0 end)
			+@lProcfix_co*@nProcfix_co)/100+@Spspec_co_baza_suma*@Baza_spspec*b.spor_specific/100
			+@Spspec_co_nu_baza_suma*(case when @Spspec_suma=1 then b.spor_specific else 0 end)
			+@Spv_co*b.spor_vechime/100*@Spv_indcond*(case when @lBuget=1 then 0 else 1 end)*b.indemnizatia_de_conducere*
			(case when @Indcond_suma=0 then b.salar_de_incadrare/100 else 1 end)
			+(case when @Indcond_suma=1 then @Indcond_co*b.indemnizatia_de_conducere else 0 end)
			+@Suma_comp+@Spfs_co*(case when @Spfs_suma=1 then b.spor_de_functie_suplimentara else 0 end)
			+@Sp1_co*(case when @Sp1_suma=1 then b.spor_conditii_1 else 0 end)
			+@Sp2_co*(case when @Sp2_suma=1 then b.spor_conditii_2 else 0 end)
			+@Sp3_co*(case when @Sp3_suma=1 then b.spor_conditii_3 else 0 end)
			+@Sp4_co*(case when @Sp4_suma=1 then b.spor_conditii_4 else 0 end)
			+@Sp5_co*(case when @Sp5_suma=1 then b.spor_conditii_5 else 0 end)
			+@Sp6_co*(case when @Sp6_suma=1 then b.spor_conditii_6 else 0 end)),0))/
			sum(dbo.Zile_lucratoare(dbo.bom(b.Data),b.Data))
		from istpers b
			left outer join infopers c on c.marca = b.marca
		where b.Data between @Data1 and @Data2 and b.Marca=@Marca

--	calcul medie zilnica dupa media venitului brut pe ultimele 3 luni
	if @CO_MVB=1
		select @Medie_zilnica=isnull((select round((select isnull(sum(venit_total)/
			round(sum((case when (case when 1=1 then ore_lucrate_regim_normal else ore_lucrate__regie+ore_lucrate_acord end)+ore_concediu_de_odihna+ore_concediu_medical+ore_obligatii_cetatenesti
			+ore_intrerupere_tehnologica+ore_concediu_fara_salar+ore_invoiri+ore_nemotivate=0 then 1000000
				else ((case when 1=1 then ore_lucrate_regim_normal else ore_lucrate__regie+ore_lucrate_acord end)+ore_concediu_de_odihna+ore_concediu_medical+ore_obligatii_cetatenesti
			+ore_intrerupere_tehnologica+ore_concediu_fara_salar+ore_invoiri+ore_nemotivate) end)/
			(case when old.spor_cond_10=0 then 8.0 else convert(float,old.spor_cond_10) end)),0),0) 
			from brut old where old.data between @Data1  and @Data2 and old.marca=personal.marca 
			and ((case when 1=1 then ore_lucrate_regim_normal else ore_lucrate__regie+ore_lucrate_acord end)+ore_concediu_de_odihna+ore_concediu_medical+
			ore_obligatii_cetatenesti+ore_intrerupere_tehnologica+ore_concediu_fara_salar+ore_invoiri+ore_nemotivate<>0 or venit_total<>0)),3))*(convert(float,1)),0)
		from personal 
		where marca=@Marca
--	compar media zilnica din istoric cu media zilnica a lunii curente
	If @OUG65=1 or @CO_MVB=1
		set @Indemnizatie_CO=(case when round(@Zile_CO*@Medie_zilnica,0)>round(@Indemnizatie_CO,0) and not (@COEV_macheta=1 and @Tip_concediu in ('2','E'))
			then round(convert(decimal(12,2),@Zile_CO*@Medie_zilnica),2) else @Indemnizatie_CO end)

	if @tip_concediu='E'
		select @Indemnizatie_CO=round(@Zile_CO*@Regim_lucru*Salar_de_incadrare/convert(float,@Regim_lucru*@nOre_luna/8),2) from personal where marca=@marca

	return (@Indemnizatie_CO)
End
