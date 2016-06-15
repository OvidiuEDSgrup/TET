--***
create procedure wACMFPublice @sesiune varchar(50), @parXML XML
as
 
declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(cod) as cod,rtrim(denumire) as denumire
from MFpublice
where denumire like '%'+@searchText+'%' or cod like @searchText+'%'
order by rtrim(cod)
for xml raw
