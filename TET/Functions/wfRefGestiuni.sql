--***
create function wfRefGestiuni (@Gestiune char(9)) returns int
as begin
	declare @Sub char(9), @FolGest int
	set @Sub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	set @FolGest=isnull((select max(convert(int, val_logica)) from par where tip_parametru='GE' and parametru='FOLGEST'), '')
	
	if exists (select 1 from stocuri where subunitate=@Sub and cod_gestiune=@Gestiune and (@FolGest=1 or tip_gestiune<>'F') and tip_gestiune<>'T')
		return 1
	if exists (select 1 from istoricstocuri where subunitate=@Sub and cod_gestiune=@Gestiune and (@FolGest=1 or tip_gestiune<>'F') and tip_gestiune<>'T')
		return 2
	if exists (select 1 from gestiuni g, rulaje r where g.subunitate=@Sub and g.cod_gestiune=@Gestiune and g.tip_gestiune='V' and r.subunitate=g.subunitate and r.cont=g.cont_contabil_specific)
		return 3
	return 0
end
