--***
/**	procedura pentru recalcul indemnizatie CO functie de media zilnica pe ultimele X luni */
Create procedure pRecalcul_CO
	@dataJos datetime, @dataSus datetime, @MarcaJos char(6), @MarcaSus char(6), @LocmJos char(9), @LocmSus char(9) 
As
Begin try
	declare @Ore_luna float, @OreM_luna float, @Spv_CO int,@Spfs_CO int,@Spsp_CO int,@Spspp_CO int, @Indc_CO int, 
		@Sp1_CO int, @Sp2_CO int,@Sp3_CO int, @Sp4_CO int,@Sp5_CO int,@Sp6_CO int, @Sp7_CO int, @dataJos_CO datetime, @dataSus_CO datetime, @Elcond int, @Term char(8)

	Set @Ore_luna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	Set @OreM_luna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
	Set @Spv_co=dbo.iauParL('PS','CO-SP-V')
	Set @Spfs_co=dbo.iauParL('PS','CO-F-SPL')
	Set @Spsp_co=dbo.iauParL('PS','CO-SPEC')
	Set @Spspp_co=dbo.iauParL('PS','CO-S-PR')
	Set @Indc_co=dbo.iauParL('PS','CO-IND')
	Set @Sp1_co=dbo.iauParL('PS','CO-SP1')
	Set @Sp2_co=dbo.iauParL('PS','CO-SP2')
	Set @Sp3_co=dbo.iauParL('PS','CO-SP3')
	Set @Sp4_co=dbo.iauParL('PS','CO-SP4')
	Set @Sp5_co=dbo.iauParL('PS','CO-SP5')
	Set @Sp6_co=dbo.iauParL('PS','CO-SP6')
	Set @Sp7_co=dbo.iauParL('PS','CO-SP7')
	Set @dataJos_CO=dbo.eom(dateadd(month,-3,@dataJos))
	Set @dataSus_CO=dbo.eom(dateadd(month,-1,@dataJos))
	Set @Elcond=dbo.iauParL('SP','ELCOND')
	Set @Term=isnull((select convert(char(8), abs(convert(int, host_id())))),'')

	update brut set 
	ind_concediu_de_odihna=round(convert(decimal(15,5),(case when ore_concediu_de_odihna*
		isnull((select sum(ind_regim_normal+@Spv_CO*spor_vechime+@Spfs_CO*spor_de_functie_suplimentara+@Spsp_CO*spor_specific+ @Spspp_CO*spor_sistematic_peste_program+@Indc_CO*ind_nemotivate
		+@Sp1_CO*spor_cond_1+@Sp2_CO*spor_cond_2+@Sp3_CO*spor_cond_3+ @Sp4_CO*spor_cond_4+@Sp5_CO*spor_cond_5+@Sp6_CO*spor_cond_6+@Sp7_CO*spor_cond_7+ind_obligatii_cetatenesti
		+(case when @Elcond=0 then ind_concediu_de_odihna else 0 end))/(case when sum(ore_lucrate_regim_normal+ore_obligatii_cetatenesti+(case when @Elcond=0 then ore_concediu_de_odihna else 0 end))=0 then 1 
			else sum(ore_lucrate_regim_normal+ore_obligatii_cetatenesti+(case when @Elcond=0 then ore_concediu_de_odihna else 0 end)) end)
		from brut old where old.marca=brut.marca and old.data between @dataJos_CO and @dataSus_CO),0) 
		>ind_concediu_de_odihna 
		then ore_concediu_de_odihna*isnull((select sum(ind_regim_normal+@Spv_CO*spor_vechime+@Spfs_CO*spor_de_functie_suplimentara+@Spsp_CO*spor_specific
		+@Spspp_CO*spor_sistematic_peste_program+@Indc_CO*ind_nemotivate+@Sp1_CO*spor_cond_1+ @Sp2_CO*spor_cond_2+@Sp3_CO*spor_cond_3+@Sp4_CO*spor_cond_4+@Sp5_CO*spor_cond_5+@Sp6_CO*spor_cond_6+
		@Sp7_CO*spor_cond_7+ind_obligatii_cetatenesti+(case when @Elcond=0 then ind_concediu_de_odihna else 0 end))/
			(case when sum(ore_lucrate_regim_normal+ore_obligatii_cetatenesti+(case when @Elcond=0 then ore_concediu_de_odihna else 0 end))=0 then 1 
			else sum(ore_lucrate_regim_normal+ore_obligatii_cetatenesti+(case when @Elcond=0 then ore_concediu_de_odihna else 0 end)) end) 
		from brut old where old.marca=brut.marca and old.data between @dataJos_CO and @dataSus_CO),0) else ind_concediu_de_odihna end)),0), 
	ind_obligatii_cetatenesti=round(convert(decimal(15,5),(case when @Elcond=0 then ind_obligatii_cetatenesti when ore_obligatii_cetatenesti*
		isnull((select sum(ind_regim_normal+@Spv_CO*spor_vechime+@Spfs_CO*spor_de_functie_suplimentara+@Spsp_CO*spor_specific+@Spspp_CO*spor_sistematic_peste_program
		+@Indc_CO*ind_nemotivate+@Sp1_CO*spor_cond_1+ @Sp2_CO*spor_cond_2+@Sp3_CO*spor_cond_3+@Sp4_CO*spor_cond_4+@Sp5_CO*spor_cond_5+@Sp6_CO*spor_cond_6
		+ind_intrerupere_tehnologica+ind_invoiri+ind_obligatii_cetatenesti+(case when @Elcond=0 then ind_concediu_de_odihna else 0 end))/
		(case when sum(ore_lucrate_regim_normal+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti+(case when @Elcond=0 then ore_concediu_de_odihna else 0 end))=0 then 1 
			else sum(ore_lucrate_regim_normal+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti+(case when @Elcond=0 then ore_concediu_de_odihna else 0 end)) end)
		from brut old where old.marca=brut.marca and old.data between @dataJos_CO and @dataSus_CO),0) 
		>ind_obligatii_cetatenesti then ore_obligatii_cetatenesti*isnull((select sum(ind_regim_normal+@Spv_CO*spor_vechime+@Spfs_CO*spor_de_functie_suplimentara+@Spsp_CO*spor_specific
		+@Spspp_CO*spor_sistematic_peste_program+@Indc_CO*ind_nemotivate+@Sp1_CO*spor_cond_1+@Sp2_CO*spor_cond_2+ @Sp3_CO*spor_cond_3+@Sp4_CO*spor_cond_4+@Sp5_CO*spor_cond_5+@Sp6_CO*spor_cond_6
		+ind_intrerupere_tehnologica+ind_invoiri+ind_obligatii_cetatenesti+(case when @Elcond=0 then ind_concediu_de_odihna else 0 end))/
			(case when sum(ore_lucrate_regim_normal+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti+(case when @Elcond=0 then ore_concediu_de_odihna else 0 end))=0 then 1 
			else sum(ore_lucrate_regim_normal+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti+(case when @Elcond=0 then ore_concediu_de_odihna else 0 end)) end)
		from brut old where old.marca=brut.marca and old.data between @dataJos_CO and @dataSus_CO),0) 
		else ind_obligatii_cetatenesti end)),0) 
	from personal 
	where brut.data=@dataSus and brut.marca between @MarcaJos and @MarcaSus 
		and personal.loc_de_munca between @LocmJos and @LocmSus and brut.marca=personal.marca
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura pRecalcul_CO (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch

