--***
Create procedure wACCatinfop @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(cod) as cod, rtrim(denumire) as denumire
from catinfop
where (cod like @searchText+'%' or denumire like '%'+@searchText+'%')
order by cod
for xml raw
