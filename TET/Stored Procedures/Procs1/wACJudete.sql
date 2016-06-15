--***
CREATE procedure wACJudete @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(cod_judet) as cod,rtrim(denumire) as denumire
from judete
where cod_judet like @searchText+'%' or denumire like '%'+@searchText+'%'
order by rtrim(cod_judet)
for xml raw
