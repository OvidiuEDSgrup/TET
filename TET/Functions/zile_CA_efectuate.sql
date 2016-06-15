--***
/**	fct pt. calcul zile CA (concedii alte) efectuate */
Create
function zile_CA_efectuate (@Marca char(6), @Data datetime, @Data_inceput datetime, @Tip_concediu char(1))
Returns int
As
Begin
	Declare @Zile_CA_efectuate int, @DataJ datetime, @DataS datetime
	Set @DataJ=dbo.boy(@data)
	Set @DataS=dbo.eoy(@data)
	select @Zile_CA_efectuate=isnull((select sum(Zile) from conalte 
	where data between @DataJ and @DataS and marca=@Marca 
		and (@Data_inceput in ('01/01/1901','') or Data_inceput<>@Data_inceput) 
		and (@Tip_concediu='' or tip_concediu=@Tip_concediu)),0) 

	Return round(@Zile_CA_efectuate,0)
End
