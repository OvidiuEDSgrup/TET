--***
create procedure rapDateTB @sesiune varchar(50), @datajos datetime, @datasus datetime, @indicator varchar(50)
as
begin
	set transaction isolation level read uncommitted
	select data Data, element_1, element_2, element_3, element_4, element_5, valoare
	from expval where tip='E' and data between @datajos and @datasus and cod_indicator=@indicator
end
