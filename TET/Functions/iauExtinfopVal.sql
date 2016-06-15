--***
/**	functie citire valoare din extinfop */
create function iauExtinfopVal 
	(@Marca char(6), @Cod_inf char(20)) 
returns varchar(80)
as
begin
	return isnull((select rtrim(max(val_inf)) from extinfop where Marca = @Marca and Cod_inf = @Cod_inf), '')
end
