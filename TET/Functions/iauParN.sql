--***
create function iauParN (@tip char(2), @par char(9)) returns float 
as
begin
	return isnull((select max(val_numerica) from par where tip_parametru = @tip and parametru = @par), 0)
end
