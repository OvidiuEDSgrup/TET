--***
create function denAtribuireConturi(@atribuire float) returns varchar(20)
as begin
	return 
	(case @atribuire 
		when 0 then 'Neatribuit' 
		when 1 then 'Furnizori' 
		when 2 then 'Beneficiari' 
		when 3 then 'Stocuri' 
		when 4 then 'Valoare MF' 
		when 5 then 'Amortizare MF' 
		when 6 then 'TVA deductibila' 
		when 7 then 'TVA colectata' 
		when 8 then 'Efecte' 
		when 9 then 'Deconturi sal.' 
		else ''
	end)
end
