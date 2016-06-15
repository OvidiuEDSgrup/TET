--***
/**	functie fCalendar	*/
Create
function fCalendar (@DataJ datetime, @DataS datetime)
returns @calstd table
	(Data datetime, Data_lunii datetime, An smallint, Luna smallint, LunaAlfa char(15), Zi smallint, Saptamana smallint, Trimestru smallint, 
	Zi_alfa char(10), Fel_zi char(1))
as
begin

	DECLARE @I INT,@DDATA DATETIME,@DDATAL DATETIME,@DDATAST DATETIME,@NAN INT,@nZi int,@cZiChar char(10), @cLunaAlfa char(15), @zileinan INT
	SET @NAN=(case when @DataS in ('01/01/1901','') then 2010 else year(@DataS) end)
	
	SET @zileinan = 365 + case when (( @NAN  % 4 = 0 AND @NAN  % 100 != 0) OR @NAN  % 400 = 0) then 1 else 0 end
	SET @zileinan = (case when @DataS in ('01/01/1901','') then @zileinan else DateDiff(day,@DataJ,@DataS)+1 end)

--DELETE FROM CALSTD WHERE YEAR(DATA)=@NAN
	SET @I=0
	SET @DDATAST=CONVERT(DATETIME,'01/01/'+RTRIM(STR(@NAN)))
	SET @DDATAST=(case when @DataS in ('01/01/1901','') then @DDATAST else @DataJ end)

	While @I<@zileinan
	Begin
		SET @DDATA=DATEADD(DAY,@i,@DDATAST)
		SET @DDATAL=dateadd(day, -day(dateadd(month, 1, @dData)), dateadd(month, 1, @dData))
		Set @nZi=datepart(weekday,@dData)
		set @cZiChar=(case when @nZi=1 then 'Duminica' 
			when @nZi=2 then 'Luni' 
			when @nZi=3 then 'Marti' 
			when @nZi=4 then 'Miercuri' 
			when @nZi=5 then 'Joi' 
			when @nZi=6 then 'Vineri' 
			else 'Sambata' end)
		set @cLunaAlfa=(case when datepart(month,@dData)=1 then 'Ianuarie'
			when datepart(month,@dData)=2 then 'Februarie'
			when datepart(month,@dData)=3 then 'Martie'
			when datepart(month,@dData)=4 then 'Aprilie'
			when datepart(month,@dData)=5 then 'Mai'
			when datepart(month,@dData)=6 then 'Iunie'
			when datepart(month,@dData)=7 then 'Iulie'
			when datepart(month,@dData)=8 then 'August'
			when datepart(month,@dData)=9 then 'Septembrie'
			when datepart(month,@dData)=10 then 'Octombrie'
			when datepart(month,@dData)=11 then 'Noiembrie'
			else 'Decembrie' end)
		INSERT INTO @CALSTD(Data,Data_lunii,An,Luna,LunaAlfa,Zi,Saptamana,Trimestru,Zi_alfa,Fel_zi)
		VALUES(@dData,@dDatal,datepart(year,@dData),datepart(month,@dData),@cLunaAlfa,datepart(day,@dData),datepart(week,@dData),datepart(quarter,@dData),@cZiChar,(case when @cZiChar in ('Sambata','Duminica') then 'N' else 'L' end))
		SET @I=@I+1
	End
	return
End
