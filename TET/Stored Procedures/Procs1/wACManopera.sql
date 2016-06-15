--***
create procedure [dbo].[wACManopera] @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select 
	rtrim(catop.cod) cod, (rtrim(catop.Denumire)+ ' '+rtrim(isnull(p.Utilizator,'')) )as denumire,
	(rtrim(devauto.Executant))as info
from catop 
	inner join pozdevauto p on catop.Cod=p.Cod_deviz
	inner join devauto on devauto.Cod_deviz=p.Cod_deviz 
	
where (catop.cod like @searchText+'%')
	or (catop.Denumire like '%'+@searchText+'%')

order by cod
for xml raw
