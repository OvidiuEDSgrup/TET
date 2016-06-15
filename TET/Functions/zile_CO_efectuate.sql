--***
/**	functie pentru calcul zile CO efectuate (din CO) */
Create function zile_CO_efectuate 
	(@Marca char(6), @Data datetime, @Data_inceput datetime, @Tipuri_concedii char(10))
Returns int
As
Begin
	Declare @Zile_CO_efectuate int, @dataJos datetime, @dataSus datetime
	set @dataJos=dbo.boy(@data)
	set @dataSus=(case when @Data_inceput in ('01/01/1901','') then dbo.eoy(@data) else dbo.eom(@data) end)

	select @Zile_CO_efectuate=isnull((select sum(Zile_CO) 
	from concodih where data between @dataJos and @dataSus and marca=@Marca 
		and (@Data_inceput in ('01/01/1901','') or Data_inceput<>@Data_inceput) 
		and tip_concediu not in ('9','C','V','P') 
		and (@Tipuri_concedii='' or charindex(tip_concediu,@Tipuri_concedii)<>0)),0) 

	Return round(@Zile_CO_efectuate,0)
End
