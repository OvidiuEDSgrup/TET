--***
/**	functie suma cifrelor din sir	*/
Create function  fSuma_cifrelor (@Sir_de_cifre  char(5000))
Returns int
As
Begin
	Declare @Suma_cifrelor int, @Sir_ramas char(1000)
	Set @Sir_ramas=@Sir_de_cifre
	Set @Suma_cifrelor = 0
	while len(ltrim(rtrim(@Sir_ramas)))>1
	Begin
		Set @Suma_cifrelor = @Suma_cifrelor+convert(int,right(ltrim(rtrim(@Sir_ramas)),1))
		Set @Sir_ramas=left(@Sir_ramas,len(ltrim(rtrim(@Sir_ramas)))-1)
	End
	Set @Suma_cifrelor=@Suma_cifrelor+convert(int,ltrim(rtrim(@Sir_ramas)),1)
	Return (@Suma_cifrelor)
End
