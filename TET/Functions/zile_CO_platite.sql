--***
/**	functie calcul zile CO platite	*/
Create
function zile_CO_platite (@Marca char(6), @Data datetime)
Returns float
As
Begin
	Declare @Zile_CO_platite float, @DataJ datetime, @dataang datetime, @FormatZileCO int
	Set @FormatZileCO=dbo.iauParN('PS','FLDCORAM')
	Set @DataJ=dbo.boy(@data)
	set @dataang=(select Data_angajarii_in_unitate from personal where Marca=@Marca)
	if @dataang>@DataJ
		set @DataJ=dbo.BOM(@dataang)
		
	select @Zile_CO_platite=isnull((select round(sum(ore_concediu_de_odihna/(case when spor_cond_10=0 then 8.00 else spor_cond_10 end)),2)
	from brut where data between @DataJ and @Data and marca=@Marca),0)+ 
	isnull((select sum(Zile_CO) from concodih where data between @DataJ and @Data and marca=@Marca and tip_concediu in ('3','6')),0) 

	Return round(@Zile_CO_platite,(case when @FormatZileCO<>0 then 2 else 0 end))
End
