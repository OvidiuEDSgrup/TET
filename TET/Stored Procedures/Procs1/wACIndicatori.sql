--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori ) */

CREATE procedure  wACIndicatori  @sesiune varchar(50), @parXML XML 
as 
 
 declare @searchText varchar(80)
 
 select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
set @searchText=REPLACE(@searchText,' ','%')
declare @codcateg varchar(20)

set @codcateg=@parXML.value('(/row/@categorie)[1]','varchar(100)')

select  rtrim(i.Cod_Indicator) as cod, RTRIM(i.Denumire_Indicator) as denumire
from indicatori i
where (i.Cod_Indicator like @searchText+'%' or i.Denumire_Indicator like '%'+@searchText+'%')
and (@codcateg is null or i.Cod_Indicator in (select Cod_Ind from compcategorii where Cod_Categ=@codcateg))
order by i.Ordine_in_raport,i.Cod_Indicator
for xml raw
