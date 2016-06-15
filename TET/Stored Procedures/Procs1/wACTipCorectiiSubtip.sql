--***
Create procedure wACTipCorectiiSubtip @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(Tip_corectie_venit) as cod, '' as info, rtrim(denumire) as denumire
from tipcor
where (Tip_corectie_venit like @searchText+'%' or denumire like '%'+@searchText+'%')
order by cod
for xml raw
