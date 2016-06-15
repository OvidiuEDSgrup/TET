--***
create procedure wACLuna @sesiune varchar(50), @parXML XML
as
 
declare @searchText varchar(100) , @cod varchar(2),@month varchar(10),@year varchar(10) 
select @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select distinct DATEPART(MONTH,t.Termen) as cod,
	( case DATEPART(MONTH,t.Termen) when '1' then 'Ianuarie'
										when '2' then 'Februarie'
										when '3' then 'Martie'
										when '4' then 'Aprilie'
										when '5' then 'Mai'
										when '6' then 'Iunie'
										when '7' then 'Iulie'
										when '8' then 'August'
										when '9' then 'Septembrie'
										when '10' then 'Octombrie'
										when '11' then 'Noiembrie'
										when '12' then 'Decembrie' 
										end ) as denumire

from TERMENE t  
inner join con c on c.Contract=t.Contract and c.Stare='1' and t.Cant_realizata=0
where DATEPART(MONTH,t.Termen)like '%'+@searchText+'%' 
for xml raw
