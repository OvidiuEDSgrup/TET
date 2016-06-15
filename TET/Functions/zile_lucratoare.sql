--***
/**	functie pentru calcul zile lucratoare dintr-o perioada */
Create function zile_lucratoare 
	(@DataJ datetime, @DataS datetime)
Returns int
As
Begin
	Declare @DataIncr datetime, @Zile_lucr int
	Set @DataIncr = @DataJ
	Set @Zile_lucr = 0
	/*
	while @DataS >= @DataIncr
	Begin
		if not(datename(WeekDay, @DataIncr) in ('Sunday','Saturday') or @DataIncr in (select data from calendar))
			Set @Zile_lucr = @Zile_lucr + 1
		Set @DataIncr = dateadd(day, 1, @DataIncr)
	End
	*/
	set @zile_lucr=(select count(1) from fCalendar(@DataJ,@DataS) fc
	where fc.Zi_alfa not in ('Sambata','Duminica') and not exists (select 1 from calendar c where c.data=fc.data))
	Return (@zile_lucr)
End
