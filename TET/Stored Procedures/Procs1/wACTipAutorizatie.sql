--***
Create procedure wACTipAutorizatie @sesiune varchar(50), @parXML XML
as
Begin
	declare @searchText varchar(100), @tip varchar(2)
	select @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%'),
		@tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')

	select top 100 rtrim(cod) as cod, rtrim(descriere) as denumire, rtrim(CodParinte) as info
	from CatalogRevisal
	where TipCatalog='TipAutorizatie' and (cod like @searchText+'%' or descriere like '%'+@searchText+'%')
	order by cod
	for xml raw
End	
