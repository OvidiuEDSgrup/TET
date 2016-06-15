--***
create function wfRefLM (@LM char(9)) returns int
as begin
	declare @Sub char(9)
	set @Sub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	
	if exists (select 1 from lm where cod_parinte=@LM)
		return 1
	if exists (select 1 from pozincon where subunitate=@Sub and loc_de_munca=@LM)
		return 2
	return 0
end
