--***
/**	functie citire camp data din extinfop */
create function iauExtinfopData 
	(@Marca char(6), @Cod_inf char(20)) returns datetime
as
begin
	return isnull((select max(Data_inf) from extinfop where Marca = @Marca and Cod_inf = @Cod_inf), '')
end
