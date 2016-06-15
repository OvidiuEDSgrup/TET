--***
Create procedure wACCoduriclasif @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100), @categoria varchar(100), @raport varchar(100)
select @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%'),
		@categoria=replace(isnull(@parXML.value('(/row/@categoria)[1]','varchar(100)'),'%'),' ','%'),
		@raport=replace(isnull(@parXML.value('(/row/@raport)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(Cod_de_clasificare) as cod, 
ltrim(CONVERT(varchar(20), convert(decimal(15, 0), dur_min)))+ '-' + 
ltrim(CONVERT(varchar(20), convert(decimal(15, 0), dur_max)))+'ani('+
ltrim(CONVERT(varchar(20), convert(decimal(15, 0), dur_min*12)))+ '-' + 
ltrim(CONVERT(varchar(20), convert(decimal(15, 0), dur_max*12)))+' luni)' as info, 
rtrim(denumire) as denumire
from Codclasif
where (Cod_de_clasificare like @searchText+'%' or denumire like '%'+@searchText+'%')
	and (nullif(@raport,'%') is null or @categoria is null or Cod_de_clasificare like @categoria+'%')
and Este_grup=0
order by Cod_de_clasificare
for xml raw
