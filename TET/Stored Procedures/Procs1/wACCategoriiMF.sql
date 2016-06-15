--***
Create procedure wACCategoriiMF @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(replace(Cod_de_clasificare,'.','')) as cod, 
ltrim(CONVERT(varchar(20), convert(decimal(15, 0), dur_min)))+ '-' + 
ltrim(CONVERT(varchar(20), convert(decimal(15, 0), dur_max)))+'ani('+
ltrim(CONVERT(varchar(20), convert(decimal(15, 0), dur_min*12)))+ '-' + 
ltrim(CONVERT(varchar(20), convert(decimal(15, 0), dur_max*12)))+' luni)' as info, 
rtrim(denumire) as denumire
from Codclasif
where (Cod_de_clasificare like @searchText+'%' or denumire like '%'+@searchText+'%')
	and (len(Cod_de_clasificare)<3 or left(cod_de_clasificare,1)='2' and len(replace(cod_de_clasificare,'.',''))<3)
order by Cod_de_clasificare
for xml raw
