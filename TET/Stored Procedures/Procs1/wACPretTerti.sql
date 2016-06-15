--***
Create procedure wACPretTerti @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100  
(rtrim(p.Tert))as cod, (rtrim (t.Denumire))as denumire 
    
from ppreturi p    
inner join terti t on p.tert=t.tert
where (p.Tert like @searchText+'%')

order by p.Tert
for xml raw
