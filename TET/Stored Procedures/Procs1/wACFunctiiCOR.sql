--***
Create procedure  wACFunctiiCOR  @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(cod_functie) as cod, rtrim(cod_functie) as info, rtrim(denumire) as denumire
from functii_cor a
where (numar_curent like @searchText+'%' or cod_functie like @searchText+'%' 
or denumire like '%'+@searchText+'%')
order by numar_curent
for xml raw
