--***
Create procedure wACCategSal @sesiune varchar(50), @parXML XML
as
Begin
	declare @searchText varchar(100)
	set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

	select top 100 rtrim(Categoria_salarizare) as cod, '' as info, rtrim(c.Descriere) as denumire
	from categs c
	where (Categoria_salarizare like @searchText+'%' or Descriere like '%'+@searchText+'%')
	order by Categoria_salarizare
	for xml raw
End
