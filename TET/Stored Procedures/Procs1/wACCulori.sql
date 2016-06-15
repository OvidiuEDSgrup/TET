--***
Create procedure wACCulori @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)

set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 
(rtrim(c.Cod_culoare))as cod, (rtrim(c.Denumire))as denumire 
from Culori c
where (c.Cod_culoare like @searchText+'%' or c.Denumire like '%'+@searchText+'%')
order by cod
for xml raw
