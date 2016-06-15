--***
Create procedure  wACCasaSan  @sesiune varchar(50), @parXML XML
as

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(marca) as cod, rtrim(val_inf) as denumire
from extinfop
where (marca like @searchText+'%' or val_inf like '%'+@searchText+'%') and cod_inf='#CASSAN'
order by marca
for xml raw
