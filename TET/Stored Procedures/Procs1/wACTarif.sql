--***
Create procedure [dbo].[wACTarif] @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 
(rtrim(c.Cod))as cod, (rtrim(c.Denumire) )as denumire, 
               (rtrim(c.tarif))as info

from catop  c
	inner join pozdevauto p on c.Cod=p.Cod_deviz
	inner join devauto on devauto.Cod_deviz=p.Cod_deviz 
	
where (c.Denumire like '%'+@searchText+'%') 
     or (c.Cod like '%'+@searchText+'%')


order by cod
for xml raw
