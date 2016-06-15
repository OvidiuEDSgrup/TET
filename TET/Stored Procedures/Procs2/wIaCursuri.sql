--***
CREATE procedure wIaCursuri @sesiune varchar(50), @parXML xml
as    
declare @valuta varchar(3)
select @valuta=isnull(@parXML.value('(/row/@valuta)[1]','varchar(3)'),'')

select top 100 convert(char(10),Data,101) as data, 
	convert(decimal(12,4),curs) as curs,RTRIM(valuta) as valuta, RTRIM(tip) as tip_valuta  
from curs  
where Valuta=@valuta 
order by convert(datetime,data) desc 
for xml raw

/*
select * from curs
*/
