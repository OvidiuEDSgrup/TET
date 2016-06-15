--***
/**	functie valoare maxima	*/
Create
function valoare_maxima (@valoare1 float, @valoare2 float, @valoare_maxima float)
Returns float
As
Begin
	Set @valoare_maxima = (case when @valoare1>@valoare2 then @valoare1 else @valoare2 end)

	Return (@valoare_maxima)
End
