--***
create function denTipGestiune(@Tip char(1)) returns varchar(20)
as begin
	return 
	(case @Tip 
		when 'M' then 'Materiale' 
		when 'P' then 'Produse' 
		when 'C' then 'Cantitativa' 
		when 'A' then 'Amanuntul' 
		when 'V' then 'Valorica' 
		when 'O' then 'Obiecte' 
		when 'I' then 'Imobilizari' 
		when 'F' then 'Folosinta'
		when 'T' then 'Custodie'
		else '' 
	end)
end
