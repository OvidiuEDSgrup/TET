--***
/**	functie iauPar lunari N	*/
create function iauParLN 
(@Data datetime, @tip char(2), @par char(9)) returns float 
as
begin
	return isnull((select max(val_numerica) from par_lunari where Data = @Data and tip = @tip and parametru = @par), 0)
end
