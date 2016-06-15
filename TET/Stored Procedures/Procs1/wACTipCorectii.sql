--***
Create procedure wACTipCorectii @sesiune varchar(50), @parXML XML
as

declare @Subtipcor int
Set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(Tip_corectie_venit) as cod, '' as info, rtrim(denumire) as denumire
from tipcor
where @Subtipcor=0 and (Tip_corectie_venit like @searchText+'%' or denumire like '%'+@searchText+'%')
union all
select top 100 rtrim(a.Subtip) as cod, rtrim(b.Denumire) as info, rtrim(a.denumire) as denumire
from subtipcor a
left outer join tipcor b on a.Tip_corectie_venit=b.Tip_corectie_venit
where @Subtipcor=1 and (subtip like @searchText+'%' or a.denumire like '%'+@searchText+'%')
order by cod
for xml raw
