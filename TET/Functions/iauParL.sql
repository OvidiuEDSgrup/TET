--***
create function iauParL (@tip char(2), @par char(9)) returns int 
as
begin
	return isnull((select max(convert(int, val_logica)) from par where tip_parametru = @tip and parametru = @par), 0)
end
