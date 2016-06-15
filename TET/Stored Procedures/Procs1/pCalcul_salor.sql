--***
/**	procedura pentru calcul salar orar */
Create procedure pCalcul_salor
	@dataJos datetime, @dataSus datetime, @MarcaJos char(6), @MarcaSus char(6), @LocmJos char(9), @LocmSus char(9) 
As
Begin try
	declare @Ore_luna float, @OreM_luna float, @Ore_luna_ocaz float, @Ore_luna_tura float, @Buget int, @RegimLV int, 
		@Fortrans int, @Dafora int, @Somesana int
	
	set @Ore_luna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @OreM_luna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
	set @Ore_luna_ocaz=dbo.iauParN('PS','ORE_OC3')
	set @Ore_luna_tura=dbo.iauParLN(@dataSus,'PS','ORET_LUNA')
	set @Buget=dbo.iauParL('PS','UNITBUGET')
	set @RegimLV=dbo.iauParL('PS','REGIMLV')
	set @Fortrans=dbo.iauParL('SP','FORTRANS')
	set @Dafora=dbo.iauParL('SP','DAFORA')
	set @Somesana=dbo.iauParL('SP','SOMESANA')

	insert into #salor 
	select pontaj.Data, pontaj.Marca, round((case when pontaj.tip_salarizare in ('6','7') then pontaj.salar_categoria_lucrarii when @Buget=1 then personal.salar_de_baza 
		else personal.salar_de_incadrare end)/(case when pontaj.tip_salarizare in ('6','7') then 1 when (@Dafora=1 or @RegimLV=1) and personal.salar_lunar_de_baza>0 
			then personal.salar_lunar_de_baza*(case when pontaj.tip_salarizare in ('1', '2') and @Dafora=0 then convert(decimal(12,0),@Ore_luna)/convert(decimal(12,0),@OreM_luna) else 1 end) 
			when pontaj.tip_salarizare='1' or pontaj.tip_salarizare='2' or (@Fortrans=1 and  pontaj.tip_salarizare='3') 
			then (case when regim_de_lucru=3 and personal.grupa_de_munca in ('O','P') then @Ore_luna_ocaz else @Ore_luna*regim_de_lucru/8 end) else @OreM_luna*regim_de_lucru/8 end),4), 
	pontaj.loc_de_munca, pontaj.ore_regie+pontaj.ore_acord as ore_lucrate, pontaj.regim_de_lucru, pontaj.numar_curent 
	from personal, pontaj 
	where pontaj.data between @dataJos and @dataSus and pontaj.marca between @MarcaJos and @MarcaSus 
		and pontaj.marca=personal.marca 
--		and pontaj.loc_de_munca between @LocmJos and @LocmSus
--		24.09.2012 - am tratat sa faca filtrarea functie de locul de munca din personal (in loc de pontaj) pt. a efectua calcul complet pe o marca la filtru pe loc de munca.
		and personal.loc_de_munca between @LocmJos and @LocmSus

	if @Dafora=1 or @RegimLV=1
		update #salor set salar_orar=(case when @Dafora=1 and not(pontaj.tip_salarizare='1' and pontaj.ore_regie=@Ore_luna) 
			then round(#salor.salar_orar*1000/5,0)*5/1000 else #salor.salar_orar end), 
		regim_de_lucru=(case when personal.salar_lunar_de_baza=0 
			then (case when personal.grupa_de_munca not in ('C','O') and pontaj.regim_de_lucru<6 or pontaj.regim_de_lucru=0 then 8 else pontaj.regim_de_lucru end) 
			else round(personal.salar_lunar_de_baza/(case when pontaj.tip_salarizare in ('1', '2') and (1=0 or @Dafora=1) then @Ore_luna when @Ore_luna_tura<>0 then @Ore_luna_tura 
				else @OreM_luna end)*8, (case when @Dafora=1 then 2 else 0 end)) end) 
		from personal, pontaj, #salor 
		where pontaj.data between @dataJos and @dataSus and pontaj.marca between @MarcaJos and @MarcaSus 
--			and pontaj.loc_de_munca between @LocmJos and @LocmSus 
			and personal.loc_de_munca between @LocmJos and @LocmSus 
			and pontaj.marca=personal.marca and pontaj.Data=#salor.Data and pontaj.marca=#salor.marca 
			and pontaj.loc_de_munca=#salor.loc_de_munca and pontaj.numar_curent=#salor.numar_curent

	if @Somesana=1
		update #salor set Ore_lucrate=(select (case when 1=0 then (@Ore_luna/8)*pontaj.regim_de_lucru-(pontaj.Ore_intrerupere_tehnologica+pontaj.Ore+pontaj.Ore_obligatii_cetatenesti 
			+pontaj.Ore_concediu_fara_salar+pontaj.Ore_concediu_de_odihna+pontaj.Ore_concediu_medical+pontaj.Ore_invoiri +pontaj.Ore_nemotivate) else pontaj.ore_regie end) 
		from pontaj 
		where pontaj.data between @dataJos and @dataSus and pontaj.marca between @MarcaJos and @MarcaSus 
			and pontaj.loc_de_munca between @LocmJos and @LocmSus and pontaj.Data=#salor.Data and pontaj.marca=#salor.marca 
			and pontaj.loc_de_munca=#salor.loc_de_munca and pontaj.numar_curent=#salor.numar_curent)
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura pCalcul_salor (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch

