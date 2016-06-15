--***
create function wfRefConturi(@Cont varchar(40)) returns int
as begin
	declare @Sub char(9)
	set @Sub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	
	if exists (select 1 from conturi where subunitate=@Sub and cont_parinte=@Cont)
		return 1
	if exists (select 1 from rulaje where subunitate=@Sub and cont=@Cont)
		return 2
	if exists (select 1 from pozincon where subunitate=@Sub and (cont_debitor=@Cont or cont_creditor=@Cont))
		return 3
	return 0
end
