
create procedure wACUM @sesiune varchar(50), @parXML XML
as
 
	declare 
		@searchText varchar(100)
	select
		@searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

	select top 100 
		rtrim(UM) as cod,rtrim(denumire) as denumire
	from um	where denumire like '%'+@searchText+'%' or UM like @searchText+'%'
	order by rtrim(UM)
	for xml raw, root('Date')
