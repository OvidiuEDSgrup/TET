--***
/**	functie iauPar lunari D	*/
create function iauParLD 
(@Data datetime, @tip char(2), @par char(9)) returns datetime 
as
begin
	return isnull((select max(val_data) from par_lunari where Data = @Data and tip = @tip and parametru = @par), 0)
end
