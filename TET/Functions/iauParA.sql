--***
create function iauParA (@tip char(2), @par char(9)) returns char(200)
as
begin
	return isnull((select max(val_alfanumerica) from par where tip_parametru = @tip and parametru = @par), '')
end
