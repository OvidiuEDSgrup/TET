
create procedure wIaValute @sesiune varchar(50), @parXML xml 
as  

declare @valuta varchar(8) , @denumire varchar(50) ,@f_denumire varchar(50),@f_valuta varchar(10), @utilizator varchar(20)
    
select @f_denumire=isnull(@parXML.value('(/row/@f_denumire)[1]','varchar(80)'),''),
	@f_valuta=isnull(@parXML.value('(/row/@f_valuta)[1]','varchar(10)'),'')
     
select RTRIM(v.valuta) as valuta , RTRIM(v.Denumire_valuta) as denumire_valuta, 
	convert(char(10),(select top 1 data from curs where valuta=v.valuta order by convert(datetime,data) desc),101) as data_ult_curs,
	convert(decimal(12,4),(select top 1 curs from curs where valuta=v.valuta order by convert(datetime,data) desc)) ult_curs
from valuta v
where isnull(v.valuta,'') like '%'+ISNULL(@f_valuta,'')+'%'
	and isnull(v.Denumire_valuta,'') like '%'+ISNULL(@f_denumire,'')+'%'  
order by valuta 
for xml raw
/*
select * from valuta
*/		 
		 
