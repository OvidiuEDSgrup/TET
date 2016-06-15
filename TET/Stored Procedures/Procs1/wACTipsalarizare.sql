--***
Create procedure wACTipsalarizare @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(Tip_salarizare) as cod, rtrim(denumire) as denumire 
from dbo.fTip_salarizare()
where (Tip_salarizare like @searchText+'%' or denumire like '%'+@searchText+'%')
order by Tip_salarizare
for xml raw
