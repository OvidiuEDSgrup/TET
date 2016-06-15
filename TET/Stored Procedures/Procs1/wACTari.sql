--***
create procedure wACTari @sesiune varchar(50), @parXML XML
as
 
declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select rtrim(cod_tara) as cod,rtrim(denumire) as denumire
from tari
where denumire like '%'+@searchText+'%' or cod_tara like @searchText+'%'
order by rtrim(cod_tara)
for xml raw
