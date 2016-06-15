--***
CREATE procedure wACUtilizatori @sesiune varchar(50),@parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(ID) as cod,rtrim(Nume) as denumire,'Marca '+RTRIM(marca) as info
from utilizatori
where nume like '%'+@searchText+'%' or ID like @searchText+'%'
order by rtrim(id)
for xml raw
