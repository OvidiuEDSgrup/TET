--***
create function denTipNomenclator(@Tip char(1)) returns varchar(20)
as begin
	return 
	(case @Tip 
		when 'M' then 'Material' 
		when 'P' then 'Produs' 
		when 'A' then 'Marfa' 
		when 'R' then 'Servicii furnizate' 
		when 'S' then 'Servicii prestate' 
		when 'O' then 'Obiecte de inventar' 
		when 'F' then 'Mijloace fixe' 
		when 'U' then 'Nefolosit' 
		else '' 
	end)
end
