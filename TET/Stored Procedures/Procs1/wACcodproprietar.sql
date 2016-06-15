--***
Create procedure [dbo].[wACcodproprietar] @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100  
(rtrim(t.Tert))as cod, (rtrim (t.Denumire))as denumire 
    
from terti t               
where (t.Tert like @searchText+'%')

order by t.Tert
for xml raw
