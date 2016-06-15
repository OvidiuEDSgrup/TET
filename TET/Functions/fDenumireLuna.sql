/*
	functia returneaza denumirea lunii pentru data primita ca parametru
*/
create function fDenumireLuna (@data datetime)
returns varchar(50)
as 
begin
	declare @den varchar(50)
	
	set @den=
		(case datepart(month,@data) 
			when 1 then 'Ianuarie'
			when 2 then 'Februarie'
			when 3 then 'Martie'
			when 4 then 'Aprilie'
			when 5 then 'Mai'
			when 6 then 'Iunie'
			when 7 then 'Iulie'
			when 8 then 'August'
			when 9 then 'Septembrie'
			when 10 then 'Octombrie'
			when 11 then 'Noiembrie'
			else 'Decembrie' end)
	return @den
end
