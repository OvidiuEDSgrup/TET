
Create procedure wACTipVenitD205 (@sesiune varchar(50), @parXML xml)
as
begin
	declare @searchText varchar(100)
	set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

	select top 100 rtrim(tip_venit) as cod, denumire, '' as info
	from fTipVenitD205 () a
	where (tip_venit like @searchText+'%' or denumire like '%'+@searchText+'%')
	order by tip_venit
	for xml raw	
	
	return
end
