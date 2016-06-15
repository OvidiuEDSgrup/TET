--***
create function denTipIncasare(@Tip varchar(10)) returns varchar(50)
as begin
	return 
	(case @Tip 
		when '31' then 'Numerar' 
		when '34' then 'Credit' 
		when '35' then 'Tichete de masa' 
		when '36' then 'Card' 
		when '37' then 'Puncte'
		when '38' then 'Voucher'
		else @tip
	end)
end
