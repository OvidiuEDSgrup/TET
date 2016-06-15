--***
create procedure wACBanci @sesiune varchar(50), @parXML XML  
as  
  
declare @searchText varchar(100)  
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')  
  
select distinct top 100 
	rtrim(denumire) as denumire,max(rtrim(cod)) as cod, MAX(RTRIM(filiala)) as info
from bancibnr
where (cod like @searchText+'%' or denumire  like '%'+@searchText+'%')
group by rtrim(denumire)
order by rtrim(denumire)  
for xml raw
