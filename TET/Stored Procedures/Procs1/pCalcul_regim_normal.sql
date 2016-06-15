--***
/**	procedura calcul regim normal	*/
Create
procedure [dbo].[pCalcul_regim_normal]
@DataJ datetime, @DataS datetime, @MarcaJos char(6), @MarcaSus char(6), @LocmJos char(9), @LocmSus char(9) 
As
Begin
	declare @Ore_luna float, @SomajTehnic int, @ScadOS_RN int, @ScadO100_RN int, @Adun_OIT_RN int, @Somesana int, @Salubris int, @Colas int, @Term char(8)
	Set @Ore_luna=dbo.iauParLN(@DataS,'PS','ORE_LUNA')
	Set @SomajTehnic=dbo.iauParLL(@DataS,'PS','STOUG28')
	Set @ScadOS_RN=-1*dbo.iauParL('PS','OSNRN')
	Set @ScadO100_RN=-1*dbo.iauParL('PS','O100NRN')
	Set @Adun_OIT_RN=dbo.iauParL('PS','OINTNRN')
	Set @Somesana=dbo.iauParL('SP','SOMESANA')
	Set @Salubris=dbo.iauParL('SP','SALUBRIS')
	Set @Colas=dbo.iauParL('SP','COLAS')
	Set @Term=isnull((select convert(char(8), abs(convert(int, host_id())))),'')

	update brut set 
	ore_lucrate_regim_normal=(select sum(case when @Somesana=1 and 1=0 then (@Ore_luna/8)*c.regim_de_lucru -(Ore_intrerupere_tehnologica+Ore+Ore_obligatii_cetatenesti+Ore_concediu_fara_salar+Ore_concediu_de_odihna +Ore_concediu_medical+Ore_invoiri+Ore_nemotivate) else (case when @Somesana=1 then 0 else ore_acord end)+ore_regie+
	@ScadOS_RN*(ore_suplimentare_1+ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4)+@ScadO100_RN*ore_spor_100+ @Salubris*(ore_suplimentare_1+ore_suplimentare_2-ore_suplimentare_3)+(case when @Adun_OIT_RN=1 then ore_intrerupere_tehnologica+(case when @Colas=1 then spor_cond_8 else 0 /*(case when @SomajTehnic=1 then 0 else ore end)*/ end) else 0 end) end) 
	from pontaj c where c.data between @DataJ and @DataS and c.marca=brut.marca and c.loc_de_munca=brut.loc_de_munca), 
	ind_regim_normal=round((select sum((case when @Somesana=1 and 1=0 then (@Ore_luna/8)*c.regim_de_lucru- (Ore_intrerupere_tehnologica+Ore+Ore_obligatii_cetatenesti+Ore_concediu_fara_salar+Ore_concediu_de_odihna +Ore_concediu_medical+Ore_invoiri+Ore_nemotivate) else (case when @Somesana=1 then 0 else ore_acord end)+ore_regie+
	@ScadOS_RN*(ore_suplimentare_1+ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4)+@ScadO100_RN*ore_spor_100+
	@Salubris*(ore_suplimentare_1+ore_suplimentare_2-ore_suplimentare_3)+
	(case when @Adun_OIT_RN=1 then ore_intrerupere_tehnologica+
	(case when @Colas=1 then spor_cond_8 else 0 /*(case when @SomajTehnic=1 then 0 else ore end)*/ end) else 0 end) end)*d.salar_orar) 
	from pontaj c, ##salor d where c.data between @DataJ and @DataS and c.marca=brut.marca and c.loc_de_munca=brut.loc_de_munca 
	and d.HostID=@Term and c.Data=d.Data and c.marca=d.marca and c.loc_de_munca=d.loc_de_munca 
	and c.numar_curent=d.numar_curent),0)
	from personal b
	where brut.data between @DataJ and @DataS  and brut.marca between @MarcaJos and @MarcaSus 
	and brut.loc_de_munca between @LocmJos and @LocmSus and brut.marca=b.marca
End
