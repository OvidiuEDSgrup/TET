
CREATE procedure wACOrePontajZilnic (@sesiune varchar(50), @parXML xml)
as
begin
	declare @searchText varchar(100)
	set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

	if object_id('tempdb..#tipore') is not null drop table #tipore

	select convert(varchar(2),N) as tip_ore, convert(varchar(2),N) as denumire 
	into #tipore
	from tally where N<=24
	union all
	select 'CO', 'CO'
	union all
	select 'CM', 'CM'
	union all
	select 'LP', 'LP'	--	acestea vor merge in pontaj pe ore intrerupere tehnologica
	union all
	select 'FS', 'FS'
	union all
	select 'IN', 'IN'
	union all
	select 'NE', 'NE'
	union all
	select 'OB', 'OB'

	select top 100 rtrim(tip_ore) as cod, denumire, '' as info
	from #tipore
	where (tip_ore like @searchText+'%' or denumire like '%'+@searchText+'%')
	order by (case when isnumeric(tip_ore)=1 then str(tip_ore) else tip_ore end)
	for xml raw	
	
	return
end
