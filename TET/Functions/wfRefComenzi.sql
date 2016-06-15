--***
create function wfRefComenzi (@Comanda char(20)) returns int
as begin
	declare @Sub char(9)
	set @Sub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	
	if exists (select 1 from pozincon where subunitate=@Sub and comanda=@Comanda)
		return 1
	if exists (select 1 from lansmat where subunitate=@Sub and comanda=@Comanda)
		return 2
	return 0
end
