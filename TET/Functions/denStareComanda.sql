--***
create function denStareComanda(@Stare char(1)) returns varchar(20)
as begin
	return 
	(case @Stare 
		when 'S' then 'Simulare' 
		when 'P' then 'Pregatire fabricatie' 
		when 'L' then 'Lansata' 
		when 'A' then 'Alocata' 
		when 'I' then 'Inchisa' 
		when 'N' then 'Anulata' 
		when 'B' then 'Blocata' 
		else ''
	end)
end
