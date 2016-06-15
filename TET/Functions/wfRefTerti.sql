--***
create function wfRefTerti (@Tert char(13)) returns int
as begin
	declare @Sub char(9)
	set @Sub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	
	if exists (select 1 from facturi where subunitate=@Sub and tert=@Tert)
		return 1
		
	if exists (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.antetbonuri') AND type in (N'U'))
		if exists (select 1 from antetBonuri where tert=@Tert)		
			return 1
	
	return 0
end
