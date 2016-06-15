--***
create procedure wACAn @sesiune varchar(50), @parXML XML
as
 
declare @searchText varchar(100) 
select @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select distinct DATEPART(YEAR,t.Termen) as cod,
 DATEPART(YEAR,t.Termen) as denumire
from TERMENE t  
inner join con c on c.Contract=t.Contract and c.Stare='1' and t.Cant_realizata=0
where DATEPART(YEAR,t.Termen)like '%'+@searchText+'%' 
for xml raw
