--***
create procedure wACPosturiLucru @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(convert(char(3),p.Postul_de_lucru)) as cod, rtrim(p.Denumire) as denumire
from Posturi_de_lucru p
where (rtrim(convert(char(3),Postul_de_lucru)) like @searchText+'%') or (Denumire like '%'+@searchText+'%')
order by cod
for xml raw
