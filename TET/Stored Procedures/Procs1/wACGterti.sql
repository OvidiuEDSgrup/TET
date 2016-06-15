--***
CREATE procedure wACGterti @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(grupa) as cod,rtrim(denumire) as denumire
from gterti
where grupa like @searchText+'%' or denumire like '%'+@searchText+'%'
order by rtrim(grupa)
for xml raw
