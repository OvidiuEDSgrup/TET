--***
/**	functie Data sfarsit	*/
Create
	function data_sfarsit (@DataJ datetime, @Zi_lucr int)
Returns datetime
As
Begin
	Declare @DataS DATETIME, @Contor int
	Set @Datas = @DataJ
	Set @contor = 1
	while @Zi_lucr>0
	Begin
		if @contor<>1
			Set @datas = @datas + 1

		if not(datename(WeekDay, @DataS) in ('Sunday','Saturday') or @DataS in (select data from calendar))
			Set @Zi_lucr = @Zi_lucr - 1

		Set @contor = @contor + 1
	End
	Return (@datas)
End
