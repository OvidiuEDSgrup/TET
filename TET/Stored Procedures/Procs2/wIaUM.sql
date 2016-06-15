--***
CREATE procedure wIaUM @sesiune varchar(50), @parXML xml
as  
declare @UM varchar(8),@f_denumire varchar(50),@f_UM varchar(10)
    
select @f_denumire=isnull(@parXML.value('(/row/@f_denumire)[1]','varchar(80)'),''),
	@f_UM=isnull(@parXML.value('(/row/@f_UM)[1]','varchar(10)'),'')

select rtrim(um) as UM,rtrim(denumire) as denumire_UM  
from um  
where isnull(um,'') like ISNULL(@f_UM,'')+'%'
	and isnull(Denumire,'') like '%'+ISNULL(@f_denumire,'')+'%'  
order by um
for xml raw
/*
select * from um
sp_help um
*/
