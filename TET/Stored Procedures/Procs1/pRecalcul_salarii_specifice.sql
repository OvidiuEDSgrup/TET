--***
/**	procedura recalcul specifice	*/
Create procedure pRecalcul_salarii_specifice
	@dataJos datetime, @dataSus datetime, @MarcaJos char(6), @MarcaSus char(6), @LocmJos char(9), @LocmSus char(9) 
As
Begin try
	declare @Buget int, @Inst_publ int, @Ore_luna float, @OreM_luna float, @Spsp_salbaza int, @SpCond1_salbaza int, 
	@Spsp_proc_unit int, @Sp1_suma int, @Anulare_spv_1zinem int, @Spv_ore_obligatii int, @Spv_obligatii int, @Spv_ore_int int, 
	@Indcond_suma int, @CO_pontaj int, @CO_OUG65 int, @CO_MediaVB int, @MachetaCO int, @Nr_luni_MVB int, 
	@dataJos_CO datetime,@dataSus_CO datetime, @Dafora int, @Drumor int, @Colas int, @Spicul int, @DSVValcea int

--	parametrii lunari
	set @Ore_luna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @OreM_luna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
--	parametrii 
	select @Buget=max(case when parametru='UNITBUGET' then Val_logica else 0 end),
		@Inst_publ=max(case when parametru='INSTPUBL' then Val_logica else 0 end),
		@Spsp_salbaza=max(case when parametru='S-BAZA-SP' then Val_logica else 0 end),
		@SpCond1_salbaza=max(case when parametru='S-BAZA-S1' then Val_logica else 0 end),
		@Spsp_proc_unit=max(case when parametru='PROCSSPEC' then Val_logica else 0 end),
		@Sp1_suma=max(case when parametru='SC1-SUMA' then Val_logica else 0 end),
		@Anulare_spv_1zinem=max(case when parametru='SP-V-ANUL' then Val_logica else 0 end),
		@Spv_ore_obligatii=max(case when parametru='SP-V-OOBL' then Val_logica else 0 end),
		@Spv_ore_int=max(case when parametru='SP-V-OINT' then Val_logica else 0 end),
		@Indcond_suma=max(case when parametru='INDC-SUMA' then Val_logica else 0 end),
		@CO_pontaj=max(case when parametru='CO-NR-ORE' then Val_logica else 0 end),
		@CO_OUG65=max(case when parametru='CO-OUG65' then Val_logica else 0 end),
		@CO_MediaVB=max(case when parametru='MEDVB_CO' then Val_logica else 0 end),
		@MachetaCO=max(case when parametru='OPZILECOM' then Val_logica else 0 end),
		@Nr_luni_MVB=max(case when parametru='NRLUNI_CO' then Val_numerica else 0 end),
		@Dafora=max(case when parametru='DAFORA' then Val_logica else 0 end),
		@Drumor=max(case when parametru='DRUMOR' then Val_logica else 0 end),
		@Colas=max(case when parametru='COLAS' then Val_logica else 0 end),
		@Spicul=max(case when parametru='SPICUL' then Val_logica else 0 end),
		@DSVValcea=max(case when parametru='DSVET' then Val_logica else 0 end)
	from par where tip_parametru in ('PS','SP') 
		and parametru in ('UNITBUGET','INSTPUBL','S-BAZA-SP','S-BAZA-S1','PROCSSPEC','SC1-SUMA','SP-V-ANUL','SP-V-OOBL','SP-V-OINT','INDC-SUMA','CO-NR-ORE','CO-OUG65',
			'MEDVB_CO','OPZILECOM','NRLUNI_CO','DAFORA','DRUMOR','COLAS','SPICUL','DSVET')
	
	set @dataJos_CO=dbo.eom(dateadd(month,(case when @CO_MediaVB=1 then -@Nr_luni_MVB else -3 end),@dataJos))
	set @dataSus_CO=dbo.eom(dateadd(month,-1,@dataJos))

--	specific bugetari sau institutii publice
	If (@Buget=1 or @Inst_publ=1) and year(@dataSus)=2010 or @Inst_publ=1 and year(@dataSus)=2011
	Begin
		update brut set Venit_cond_normale=Venit_cond_normale-round(Ind_ore_de_noapte,0)
		from brut
			left outer join personal p on p.Marca=brut.Marca
		where data between @dataJos and @dataSus and brut.marca between @MarcaJos and @MarcaSus 
			and p.loc_de_munca between @LocmJos and @LocmSus 
			and Venit_cond_normale<>0 and Venit_cond_deosebite=0
		update brut set Venit_cond_deosebite=Venit_cond_deosebite-round(Ind_ore_de_noapte,0)
		from brut
			left outer join personal p on p.Marca=brut.Marca
		where data between @dataJos and @dataSus and brut.marca between @MarcaJos and @MarcaSus 
			and p.loc_de_munca between @LocmJos and @LocmSus and Venit_cond_deosebite<>0
		update brut set Ind_ore_de_noapte=0 
		from brut
			left outer join personal p on p.Marca=brut.Marca
		where data between @dataJos and @dataSus and brut.marca between @MarcaJos and @MarcaSus 
			and p.loc_de_munca between @LocmJos and @LocmSus 

		update brut set Ind_ore_de_noapte=isnull((select round(sum(a.Ore_de_noapte*(case when p.Spor_de_noapte>30 
			then p.Spor_de_noapte/(case when a.tip_salarizare in ('1','2') then @Ore_luna else @OreM_luna end)
			else p.Spor_de_noapte/100.00*isnull((case when year(@dataSus)=2010 then i.Salar_de_baza else p.Salar_de_baza end),p.Salar_de_baza)/
				(case when a.tip_salarizare in ('1','2') then @Ore_luna else @OreM_luna end) end)),0)
			from pontaj a
				left outer join personal p on p.marca=a.marca
				left outer join istpers i on i.data=dbo.boy(a.data)-1 and i.marca=a.marca
			where a.data between @dataJos and @dataSus and brut.marca=a.marca and brut.loc_de_munca=a.loc_de_munca 
				and a.marca between @MarcaJos and @MarcaSus --and a.loc_de_munca between @LocmJos and @LocmSus
			group by a.marca, a.loc_de_munca),0)
		from brut
			left outer join personal p on p.Marca=brut.Marca
		where brut.data=@dataSus and brut.marca between @MarcaJos and @MarcaSus 
			and p.loc_de_munca between @LocmJos and @LocmSus 

		update brut set Venit_cond_deosebite=Venit_cond_deosebite+Ind_ore_de_noapte
		where data between @dataJos and @dataSus and (@MarcaJos='' or Marca=@MarcaJos) and Venit_cond_deosebite<>0
		update brut set Venit_cond_normale=Venit_cond_normale+Ind_ore_de_noapte
		where data between @dataJos and @dataSus and (@MarcaJos='' or Marca=@MarcaJos) and Venit_cond_deosebite=0
	End
--	specific COLAS
	If @Colas=1
		update brut set Spor_cond_8=isnull((select round(sum(a.spor_cond_8*c.salar_orar*75/100),0)
			from pontaj a, #salor c
			where a.data between @dataJos and @dataSus and a.Data=c.Data and a.marca=c.marca 
				and a.loc_de_munca=c.loc_de_munca and a.numar_curent=c.numar_curent and brut.marca=a.marca 
				and brut.loc_de_munca=a.loc_de_munca and a.marca between @MarcaJos and @MarcaSus 
--				and a.loc_de_munca between @LocmJos and @LocmSus
			group by a.marca, a.loc_de_munca),0)
		from brut
			left outer join personal p on p.Marca=brut.Marca
		where brut.data=@dataSus and brut.marca between @MarcaJos and @MarcaSus 
			and p.loc_de_munca between @LocmJos and @LocmSus

--	specific DSV Valcea
	If @DSVValcea=1
		update brut set 
		spor_vechime=(case when @Anulare_spv_1zinem=1 and ore_nemotivate>7 then 0 
			else round(p.spor_vechime/100*(convert(float,ore_lucrate_regim_normal+@Spv_ore_obligatii*brut.ore_obligatii_cetatenesti+@Spv_ore_int*brut.ore_intrerupere_tehnologica)*brut.salar_orar),0) end),
		spor_cond_3=round(p.spor_conditii_3/100*convert(float,ore_lucrate_regim_normal*brut.salar_orar+(case when @Spsp_salbaza=1 then 0 else 1 end)*brut.spor_specific),0), 
		spor_cond_4=round(p.spor_conditii_4/100*convert(float,ore_lucrate_regim_normal*brut.salar_orar+(case when @Spsp_salbaza=1 then 0 else 1 end)*brut.spor_specific),0) 
		from personal p 
		where brut.data between @dataJos and @dataSus and brut.marca between @MarcaJos and @MarcaSus and brut.marca=p.marca 
			and p.loc_de_munca between @LocmJos and @LocmSus

	If (@DSVValcea=1 or @SpCond1_salbaza=1) and @Sp1_suma=0
		update brut set 
			spor_cond_1=round(p.spor_conditii_1/100*ore_lucrate_regim_normal*convert(float,p.salar_de_incadrare+
				(case when @Indcond_suma=1 then p.indemnizatia_de_conducere else round(p.salar_de_incadrare*p.indemnizatia_de_conducere/100,0) end))/@Ore_luna,0) 
		from personal p 
		where brut.data between @dataJos and @dataSus  and brut.marca between @MarcaJos and @MarcaSus 
			and p.loc_de_munca between @LocmJos and @LocmSus and brut.marca=p.marca	

--	specific Spicul
	if @Spicul=1
		update brut set 
		spor_specific=(case when loc_munca_pt_stat_de_plata=0 then 0 when @Spsp_proc_unit=1 and ore_nemotivate>7 then 0 
			else round(p.spor_specific/100*(case when tmp.ore_ce_ar_trebui>tmp.ore_pontaj then tmp.ore_pontaj else tmp.ore_ce_ar_trebui end)*p.salar_orar ,0) end) 
		from personal p, 
			(select marca, data, @Ore_luna-sum(brut.ore_concediu_de_odihna-brut.ore_concediu_medical) as ore_ce_ar_trebui, sum(brut.ore_lucrate__regie+brut.ore_lucrate_acord) as ore_pontaj 
			from brut where brut.data between @dataJos and @dataSus 
				and brut.marca between @MarcaJos and @MarcaSus and brut.loc_de_munca between @LocmJos and @LocmSus group by marca, data) as tmp 
		where brut.data between @dataJos and @dataSus  and brut.marca between @MarcaJos and @MarcaSus 
			and p.loc_de_munca between @LocmJos and @LocmSus and  brut.marca=p.marca and brut.marca=tmp.marca

--	specific Drumuri orasenesti Oradea
	If @Drumor=1
		update brut set 
		spor_de_functie_suplimentara=personal.spor_de_functie_suplimentara/100*(ore_lucrate_acord+ore_lucrate__regie)*
		personal.salar_de_incadrare/@OreM_luna 
		from personal 
		where brut.data between @dataJos and @dataSus and brut.marca between @MarcaJos and @MarcaSus 
			and personal.loc_de_munca between @LocmJos and @LocmSus and brut.marca=personal.marca and personal.tip_salarizare>'2'

	If @CO_MediaVB=1 and @MachetaCO=0
		update brut set 
		ind_concediu_de_odihna=ore_concediu_de_odihna*
			(select round((select isnull(sum(venit_total)/sum(ore_lucrate_regim_normal+ore_concediu_de_odihna+ore_concediu_medical+ore_obligatii_cetatenesti+ore_intrerupere_tehnologica),0) 
			from brut old where old.data between @dataJos_CO  and @dataSus_CO and old.marca=personal.marca 
				and old.ore_lucrate_regim_normal+old.ore_concediu_de_odihna+old.ore_concediu_medical+old.ore_obligatii_cetatenesti+old.ore_intrerupere_tehnologica<>0),3)) *(convert(float,1))
		from personal 
		where brut.data between @dataJos and @dataSus and brut.marca between @MarcaJos and @MarcaSus 
			and personal.loc_de_munca between @LocmJos and @LocmSus and brut.marca=personal.marca

	if @Dafora=0 and @CO_MediaVB=0 and @CO_pontaj=1 and @MachetaCO=0 and @CO_OUG65=1
		exec dbo.pRecalcul_CO @dataJos, @dataSus, @MarcaJos, @MarcaSus, @LocmJos, @LocmSus
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura pRecalcul_salarii_specifice (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch

