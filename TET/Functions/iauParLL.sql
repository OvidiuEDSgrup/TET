--***
/**	iauPar lunari L	*/
create function iauParLL 
(@Data datetime, @tip char(2), @par char(9)) returns int 
as
begin
	return isnull((select max(convert(int, val_logica)) from par_lunari where Data = @Data and tip = @tip and parametru = @par), 0)
end
