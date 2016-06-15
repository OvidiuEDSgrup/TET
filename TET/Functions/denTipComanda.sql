--***
create function denTipComanda(@Tip char(1)) returns varchar(20)
as begin
	return 
	(case @Tip 
		when 'P' then 'Productie terti' 
		when 'R' then 'Servicii terti' 
		when 'X' then 'Auxiliara' 
		when 'T' then 'Transport' 
		when 'S' then 'Semifabricat' 
		when 'V' then 'Servicii auxiliare' 
		when 'C' then 'Productie de masa' 
		when 'A' then 'Activitati anexe'
		when 'L' then 'Regie sectie' 
		when 'G' then 'Regie generala'
		when 'D' then 'Desfacere'
		else ''
	end)
end
