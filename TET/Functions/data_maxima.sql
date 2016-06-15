--***
Create
function data_maxima (@valoare1 datetime, @valoare2 datetime)
Returns datetime
As
Begin
	declare @data_maxima datetime
	Set @data_maxima = (case when @valoare1>@valoare2 then @valoare1 else @valoare2 end)
	Return (@data_maxima)
End
