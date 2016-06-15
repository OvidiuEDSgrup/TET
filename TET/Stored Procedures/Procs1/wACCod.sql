--***
Create procedure [dbo].[wACCod] @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 
(rtrim(p.Cod_deviz))as cod, (rtrim(devauto.Denumire_deviz)+ ' '+rtrim(p.Utilizator ) )as denumire, 
               (rtrim(devauto.Valoare_deviz))as info
from pozdevauto p
left outer join devauto  on devauto.Denumire_deviz=p.Tip_resursa

where (p.Cod_deviz like @searchText+'%')
order by cod
for xml raw
