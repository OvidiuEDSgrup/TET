--***
create function wfRefPersoaneContact (@Tert char(13), @Identificator char(5)) returns int
as begin
	declare @Sub char(9)
	set @Sub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	
	return 0
end
