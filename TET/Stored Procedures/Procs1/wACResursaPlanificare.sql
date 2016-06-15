--machetele de raportare(realizare tehn si op)
create procedure wACResursaPlanificare @sesiune varchar(50), @parXML XML  
as

	declare @tip varchar(10), @searchText varchar(100)
	set @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), '')

	set @searchText= '%'+REPLACE(@searchtext,' ','%')+'%'
	
	select
		id as cod, RTRIM(descriere) as denumire, '' as info
	from Resurse
	where cod like @searchText or descriere like @searchText
	for xml raw, root('Date')
