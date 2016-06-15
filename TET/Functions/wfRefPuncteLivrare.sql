--***
create function wfRefPuncteLivrare (@Tert char(13), @PunctLivrare char(5)) returns int
as begin
	declare @Sub char(9)
	set @Sub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	
	if exists (select 1 from doc where subunitate=@Sub and tip in ('AP', 'AS') and cod_tert=@Tert and gestiune_primitoare=@PunctLivrare)
		return 1
	return 0
end
