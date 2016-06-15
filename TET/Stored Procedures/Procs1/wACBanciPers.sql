--***
Create procedure wACBanciPers @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select distinct top 100 rtrim(banca) as cod, rtrim(banca) as denumire 
from personal
where banca like '%'+@searchText+'%' and Banca<>''
union all
select null as cod,' Toate' as denumire
union all
select '' as cod,' Necompletat' as denumire
order by denumire
for xml raw
