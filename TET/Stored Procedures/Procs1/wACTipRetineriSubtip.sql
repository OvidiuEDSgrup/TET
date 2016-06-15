--***
create procedure  wACTipRetineriSubtip  @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(a.tip_retinere) as cod, '' as info, rtrim(a.denumire_tip) as denumire
from dbo.fTip_retineri(1) a
where (tip_retinere like @searchText+'%' or denumire_tip like '%'+@searchText+'%')
order by cod
for xml raw
