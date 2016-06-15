--***
/* Procedura apelata din TBmobile pentru selectarea unui dindicator din categoria aleasa. */
CREATE procedure  wIaIndicatoriMobile  @sesiune varchar(50), @parXML XML 
as 
 
 declare @searchText varchar(80)
 
 select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
set @searchText=REPLACE(@searchText,' ','%')
declare @codcateg varchar(20)

set @codcateg=@parXML.value('(/row/@categorie)[1]','varchar(100)')

select rtrim(i.Cod_Indicator) as indicator, RTRIM(i.Denumire_Indicator) as denumire, 
	RTRIM(i.Denumire_Indicator) as denindicator/* trimit denumire pt. afisare in titlul view-ului indicator in mobile */, RTRIM(i.cod_indicator) as info
from indicatori i
where (i.Cod_Indicator like @searchText+'%' or i.Denumire_Indicator like '%'+@searchText+'%')
and (@codcateg is null or i.Cod_Indicator in (select Cod_Ind from compcategorii where Cod_Categ=@codcateg))
order by i.Ordine_in_raport,i.Cod_Indicator
for xml raw


--Pentru ASiSmobile
select 'wIaIndicatoriTB' as detalii,1 as areSearch,'G' as tipdetalii, '1' _toateAtr
for xml raw,Root('Mesaje')
