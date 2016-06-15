--***
Create procedure wACTipCO @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(Tip_concediu) as cod, rtrim(denumire) as denumire 
from dbo.fTip_CO()
where Tip_concediu not in ('C','P','V') and (Tip_concediu like @searchText+'%' or denumire like '%'+@searchText+'%')
order by Tip_concediu
for xml raw
