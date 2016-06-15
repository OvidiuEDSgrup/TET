--***
/**	functie valoare minima	*/
Create
function valoare_minima (@valoare1 float, @valoare2 float, @valoare_minima float)
Returns float
As
Begin
	Set @valoare_minima = (case when @valoare1>@valoare2 then @valoare2 else @valoare1 end)

	Return (@valoare_minima)
End
