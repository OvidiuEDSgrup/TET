--***
create procedure wacAntetInventar (@sesiune varchar(50), @parXML xml)
as
/*
if exists(select * from sysobjects where name='wACGestiuniSP' and type='P')      
	exec wacAntetInventarSP @sesiune,@parXML
else    */
begin
	declare @searchText varchar(200)
	select @searchText=replace(rtrim(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')),' ','%')+'%'
	select idInventar as cod, rtrim(g.Denumire_gestiune)+' ('+rtrim(gestiune)+') '+convert(varchar(20),a.data,103) as denumire,
		--convert(varchar(20),a.data,103) 
		case when isnull(a.grupa,'')<>'' then 'Grupa: ' +RTRIM(gr.Denumire)+' ('+rtrim(a.grupa)+') ' else '' end info
	from antetInventar a 
		left join gestiuni g on a.gestiune=g.Cod_gestiune
		left join grupe gr on gr.grupa=a.grupa
	where gestiune like @searchText or Denumire_gestiune like '%'+@searchText or 
		convert(varchar(20),a.data,103) like '%'+@searchText or ltrim(str(idInventar)) like @searchText+'%'
	order by a.idinventar
	for xml raw
end
