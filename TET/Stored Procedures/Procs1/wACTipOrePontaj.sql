
CREATE procedure wACTipOrePontaj (@sesiune varchar(50), @parXML xml)
as
begin
	declare @searchText varchar(100)
	set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

	if object_id('tempdb..#tipore') is not null drop table #tipore

	select 'OL' as tip_ore, 'Ore lucrate' as denumire 
	into #tipore
	union all
	select 'OD', 'Ore lucrate cu diurna'
	union all
	select 'CO', 'Concediu de odihna'
	union all
	select 'CM', 'Concediu medical'
	union all
	select 'LP', 'Liber platit'	--	acestea vor merge in pontaj pe ore intrerupere tehnologica
	union all
	select 'FS', 'Concediu fara salar'
	union all
	select 'IN', 'Invoiri'
	union all
	select 'NE', 'Nemotivate'
	union all
	select 'OB', 'Obligatii cetatenesti'

	select top 100 rtrim(tip_ore) as cod, denumire, '' as info
	from #tipore
	where (tip_ore like @searchText+'%' or denumire like '%'+@searchText+'%')
	order by denumire
	for xml raw	
	
	return
end
