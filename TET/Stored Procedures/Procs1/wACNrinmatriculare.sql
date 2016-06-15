--***
Create procedure [dbo].[wACNrinmatriculare] @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 
(rtrim(da.Cod_deviz))as cod, (rtrim(da.Denumire_deviz) )as denumire
               
from devauto da
where (da.Denumire_deviz like @searchText+'%')
order by cod
for xml raw
