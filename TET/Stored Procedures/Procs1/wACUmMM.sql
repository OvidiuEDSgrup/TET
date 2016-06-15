--***
Create procedure wACUmMM @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100), @codMasina varchar(20)

set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 
(case	when e.UM2 = 'D' then 'Luni'
		when e.UM2 = 'A' then rtrim(e.UM) 
	       				 else RTRIM(e.um2) end) as cod, 
(case	when e.UM2 = 'D' then 'Luni'
		when e.UM2 = 'A' then rtrim(e.UM) 
	       				 else RTRIM(e.um2) end)	as denumire
from elemente e
     where Tip='I'  and (e.Cod like @searchText+'%')
group by (case	when e.UM2 = 'D' then 'Luni'
		when e.UM2 = 'A' then rtrim(e.UM) 
	       				 else RTRIM(e.um2) end)	 
order by (case	when e.UM2 = 'D' then 'Luni'
		when e.UM2 = 'A' then rtrim(e.UM) 
	       				 else RTRIM(e.um2) end)
for xml raw
