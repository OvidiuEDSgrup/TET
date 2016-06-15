--***
create procedure wACComenziLivrare @sesiune varchar(50), @parXML XML
as

declare  @searchText varchar(200)
select	@searchText=@parXML.value('(/row/@searchText)[1]','varchar(20)')

select 
	rtrim(contract) as cod, rtrim(Contract)+ ' pt ' + rtrim(t.denumire) as denumire, convert(varchar(10), c.data,101) as info
from con  c
JOIN terti t on t.tert=c.tert
where c.tip='BK'
and c.Contract like '%'+@searchText+'%'
for xml raw, root('Date')
