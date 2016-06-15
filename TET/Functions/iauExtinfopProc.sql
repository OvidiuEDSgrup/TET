--***
/**	functie citire procent din extinfop */
create function iauExtinfopProc 
	(@Marca char(6), @Cod_inf char(20)) 
returns float
as
begin
	return isnull((select max(Procent) from extinfop where Marca = @Marca and Cod_inf = @Cod_inf), 0)
end

