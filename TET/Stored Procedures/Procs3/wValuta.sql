--***
CREATE procedure wValuta @sesiune varchar(50), @parXML XML  
as  

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')
  
select top 100 rtrim(valuta) as cod,rtrim(Denumire_valuta) as denumire
from valuta
where valuta like @searchText+'%' or Denumire_valuta like '%'+@searchText+'%'  
order by rtrim(valuta)
for xml raw
