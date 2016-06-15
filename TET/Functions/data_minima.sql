--***
Create
function data_minima (@valoare1 datetime, @valoare2 datetime)
Returns datetime
As
Begin
	declare @data_minima datetime
	Set @data_minima = (case when @valoare1>@valoare2 then @valoare2 else @valoare1 end)
	Return (@data_minima)
End
