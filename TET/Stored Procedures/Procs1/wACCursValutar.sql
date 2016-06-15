--***
create procedure wACCursValutar @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100),@data datetime,@valuta varchar(3)
select
	@searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%'),
	@data =ISNULL(@parXML.value('(/row/@data)[1]','datetime'),''),
	@valuta =ISNULL(@parXML.value('(/row/@valuta)[1]','varchar(3)'),'')

select top 5 CONVERT(decimal(12,4),curs) as cod,CONVERT(decimal(12,4),curs) as denumire,'din data: '+CONVERT(varchar(10),data,101)/*+',Valuta: '+RTRIM(valuta)*/ as info 
from curs
where valuta like '%'+@searchText+'%'
  and (data<=@data or @data='')
  and (valuta=@valuta or isnull(@valuta,'')='')
order by data desc
for xml raw

--select * from curs
