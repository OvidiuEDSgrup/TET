--***
/**	functie pentru calcul Zile fara tichete pt. primele X zile de la data angajarii */
Create
function psZileFaraTichete (@DataJ datetime, @DataS datetime, @Marca char(6))
Returns int
As
Begin
	Declare @PontajZilnic int, @pZileFaraTichete int, @DataIncr datetime, @ZileScutite int, @ZileNelucrate int, @DataAngajarii datetime, @DataJscut datetime, @DataSscut datetime
	Set @PontajZilnic=dbo.iauParL('PS','PONTZILN')
	Set @pZileFaraTichete=dbo.iauParN('PS','TICNUZANG')-1
	Select @DataAngajarii=Data_angajarii_in_unitate from personal where marca=@Marca

	Select @ZileScutite=0, @ZileNelucrate=0
	If @DataAngajarii>=@DataJ and @DataAngajarii<=@DataS or DateAdd(day,@pZileFaraTichete,@DataAngajarii)>=@DataJ 
	and DateAdd(day,@pZileFaraTichete,@DataAngajarii)<=@DataS or DateAdd(day,@pZileFaraTichete,@DataAngajarii)>@DataS
	Begin
		Set @DataJscut=(case when @DataAngajarii>=@DataJ and @DataAngajarii<=@DataS then @DataAngajarii else @DataJ end)
		Set @DataSscut=(case when DateAdd(day,@pZileFaraTichete,@DataAngajarii)>=@DataJ and DateAdd(day,@pZileFaraTichete,@DataAngajarii)<=@DataS 
			then DateAdd(day,@pZileFaraTichete,@DataAngajarii) else @DataS end)
		Select @ZileScutite=dbo.zile_lucratoare(@DataJscut,@DataSscut)
		Select @ZileNelucrate=isnull((select sum(dbo.Zile_lucratoare(Data_inceput,(case when Data_sfarsit<@DataSscut then Data_sfarsit else @DataSscut end))) from conmed where data=@DataS and marca=@Marca),0)+
		isnull((select sum(dbo.Zile_lucratoare(Data_inceput,(case when Data_sfarsit<@DataSscut then Data_sfarsit else @DataSscut end))*(case when tip_concediu='5' then -1 else 1 end)) 
			from concodih where data=@DataS and marca=@Marca and tip_concediu not in ('9','C','P','V')),0)
		+isnull((select sum(dbo.Zile_lucratoare(Data_inceput,(case when Data_sfarsit<@DataSscut then Data_sfarsit else @DataSscut end))) 
			from conalte where data=@DataS and marca=@Marca and (tip_concediu in ('1','4') or tip_concediu='2' and indemnizatie=0)),0)
		Select @ZileScutite=@ZileScutite-@ZileNelucrate
	End

	Return (isnull(@ZileScutite,0))
End
