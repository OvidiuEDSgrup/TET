--***
create procedure wACGrupe @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
if OBJECT_ID('wACGrupeSP') is not null
exec wACGrupeSP @sesiune, @parXML
else begin
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(grupa) as cod,rtrim(denumire) as denumire,'Tip: '+Tip_de_nomenclator as info 
from grupe
where grupa like @searchText+'%' or denumire like '%'+@searchText+'%'
order by rtrim(grupa)
for xml raw
end
