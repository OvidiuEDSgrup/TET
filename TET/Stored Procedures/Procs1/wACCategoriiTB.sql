--***
/* Procedura nu este folosita de TB- se poate sterge? */
create procedure wACCategoriiTB @sesiune varchar(50), @parXML XML 
as 
 
declare @searchText varchar(80), @titlu varchar(4)
 select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')

set @searchText=REPLACE(@searchText,' ','%')

select top 100 rtrim(Cod_categ) as cod,rtrim(Denumire_categ) as denumire
from categorii
where (Cod_categ like @searchText+'%' or Denumire_categ like '%'+@searchText+'%')
order by Cod_categ
for xml raw
