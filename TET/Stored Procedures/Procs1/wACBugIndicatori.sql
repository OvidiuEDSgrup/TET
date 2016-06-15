--***
/* Procedura apartine machetelor de configurare TB doar pentru indicatorii aferenti bugetului*/

CREATE procedure  wACBugIndicatori  @sesiune varchar(50), @parXML XML 
as 
 
 declare @searchText varchar(80),@tip varchar(2)
 
 select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
 select @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
set @searchText=REPLACE(@searchText,' ','%')
declare @codcateg varchar(20)

set @codcateg='BUGET'

select  rtrim(i.Cod_Indicator) as cod, RTRIM(i.Denumire_Indicator) as denumire,RTRIM(i.cod_indicator) as info
from indicatori i
where (i.Cod_Indicator like @searchText+'%' or i.Denumire_Indicator like '%'+@searchText+'%')
and (i.Cod_Indicator in (select Cod_Ind from compcategorii where Cod_Categ='BUGET'))
and (@tip!='CB' or Expresie=0)
order by i.Ordine_in_raport,i.Cod_Indicator
for xml raw
