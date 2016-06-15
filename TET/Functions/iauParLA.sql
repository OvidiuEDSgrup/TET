--***
/**	functie iauPar lunari D	*/
create function iauParLA 
(@Data datetime, @tip char(2), @par char(9)) returns varchar(200)
as
begin
	return isnull((select rtrim(max(val_alfanumerica)) from par_lunari where Data = @Data and tip = @tip and parametru = @par), '')
end
