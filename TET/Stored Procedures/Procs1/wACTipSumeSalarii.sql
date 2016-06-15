
CREATE procedure wACTipSumeSalarii (@sesiune varchar(50), @parXML xml)
as
begin
	declare @searchText varchar(100)
	set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

	select top 100 rtrim(tip_suma) as cod, denumire, '' as info
	from fTipSumeSalarii () a
	where (tip_suma like @searchText+'%' or denumire like '%'+@searchText+'%')
	order by denumire
	for xml raw	
	
	return
end
