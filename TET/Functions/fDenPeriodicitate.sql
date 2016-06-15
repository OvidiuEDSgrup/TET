--***
create function fDenPeriodicitate(@Tip varchar(10)) returns varchar(50)
as begin
	return 
	(case @Tip 
		when '0' then 'Fara periodicitate' 
		when '1' then 'Lunar' 
		when '2' then '2 luni' 
		when '3' then 'Trimestrial'
		when '4' then '4 luni'
		when '6' then 'Semestrial'
		when '12' then 'Anual'
		else @tip
	end)
end
