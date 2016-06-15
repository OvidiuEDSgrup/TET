--***
/**	proc.calcul net	*/
Create procedure psCalcul_net 
	@dataJos datetime, @dataSus datetime, @marcaJ char(6), @locmJ char(9), @Fara_retineri_inversare int, @Task_retineri int
As
Begin try
	declare @LocmS char(9), @Salubris int, @Codben_CONET char(13), @Calcul_GarMat int, @DiminuariL118 int, 
	@lNrMedAng int, @VenitPlafonCAS float, @NrmSalCAS float, @CoefCAS float, @VenitPlafonCCI float, @NrmSalCCI float, @CoefCCI float, 
	@NCCnph int, @par_NRM char(9), @par_CNPH char(9), @NrmCNPH float, @SumaCNPH float

	set @LocmS=rtrim(@locmJ)+'ZZ'
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	set @Codben_CONET=dbo.iauParA('PS','CODBCO')
	set @Calcul_GarMat=dbo.iauParL('PS','CALCGMAT')
	set @DiminuariL118=dbo.iauParL('PS','DIML118')
	set @lNrMedAng=dbo.iauParL('PS','NRMEDANG')
	set @NCCnph=dbo.iauParL('PS','NC-CPHAND')

	if @Task_retineri=0
	Begin
--	Lucian: 25.01.2013 pare ca nu ar fi nevoie de urmatoarele 2 randuri de mai jos. Sunt apelate cele 2 proceduri in procedurile psCalcul_venit_net, respectiv calcul_retineri_si_rest_plata
--		exec pSume_cm_marca @dataJos, @dataSus, @marcaJ
--		exec pPontaj_marca_locm @dataJos, @dataSus, @marcaJ, @locmJ
--		calcul coeficienti de plafonare CAS si CCI
		select @VenitPlafonCAS=Venit_plafonare_CAS, @NrmSalCAS=Numar_mediu_salariati_CAS, @CoefCAS=Coeficient_CAS, 
			@VenitPlafonCCI=Venit_plafonare_CCI, @NrmSalCCI=Numar_salariati_CCI, @CoefCCI=Coeficient_CCI
		from dbo.fCoeficienti_plafonare_contributii (@dataJos, @dataSus)	
		if @lNrMedAng=0
			exec setare_par 'PS','NRMEDANG','Numar mediu asigurati CAS',@lNrMedAng,@NrmSalCAS,'Numar mediu asigurati CAS'

		Select @CoefCAS=@CoefCAS*1000000
		exec setare_par 'PS', 'COEFCAS', 'Coeficient plafonare CAS', 1, @CoefCAS, 'Coeficient plafonare CAS'
		Select @CoefCCI=@CoefCCI*1000000
		exec setare_par 'PS', 'COEFCCI', 'Coeficient plafonare CCI', 1, @CoefCCI, 'Coeficient plafonare CCI'

		exec CalculSindicat @dataJos=@dataJos, @dataSus=@dataSus, @marca=@marcaJ, @lm=@locmJ
		exec psCalcul_venit_net @dataJos, @dataSus, @marcaJ, @locmJ, @Fara_retineri_inversare
		if @DiminuariL118=1
			exec psCalculContributiiL118 @dataJos, @dataSus, @marcaJ, @locmJ

--		mutat cele 4 linii de mai jos deasupra la if pt. a goli cele 2 inregistrari chiar daca nu se utilizeaza setarea (pt. cazul in care setarea a fost pusa si apoi s-a luat jos)
		Set	@par_NRM='NRM'+(case when month(@dataSus)<10 then '0' else '' end)+ rtrim(convert(char(2),month(@dataSus)))+convert(char(4),year(@dataSus))
		Set @par_CNPH='CPH'+(case when month(@dataSus)<10 then '0' else '' end)+ rtrim(convert(char(2),month(@dataSus)))+convert(char(4),year(@dataSus))
		if @marcaJ=''
		Begin
			exec setare_par 'PS', @par_NRM, 'Numar mediu salariati CNPH', 1, 0, ''
			exec setare_par 'PS', @par_CNPH, 'Contrib. neang. pers. handicap', 1, 0, ''

			if @NCCnph=1
			begin
				select @NrmCNPH=Numar_mediu_cnph, @SumaCNPH=Suma_cnph from dbo.fCalcul_cnph(@dataJos, @dataSus, '', '', 'ZZZ', '', null, null) 
				exec setare_par 'PS', @par_NRM, 'Numar mediu salariati CNPH', 1, @NrmCNPH, ''
				exec setare_par 'PS', @par_CNPH, 'Contrib. neang. pers. handicap', 1, @SumaCNPH, ''
			end
		End
	End
	if @Fara_retineri_inversare=0 and @Task_retineri=1
	Begin
		if @Codben_CONET<>''
			exec scriu_retinere_CO_net @dataJos, @dataSus, @marcaJ, @locmJ
		if @Calcul_GarMat=1
			exec dbo.psCalcul_garantii_materiale @dataJos, @dataSus, @marcaJ, @locmJ, 1
		exec CalculRetineriSiRestPlata @datajos=@dataJos, @datasus=@dataSus, @marca=@marcaJ, @lm=@locmJ
	End
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura psCalcul_net (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
