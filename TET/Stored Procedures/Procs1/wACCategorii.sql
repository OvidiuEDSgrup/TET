--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori ) */

CREATE procedure  wACCategorii  @sesiune varchar(50), @parXML XML

as

declare @searchText varchar(100)
select 
 @searchText=isnull(@parXML.value('(/row/@searchtext)[1]','varchar(100)'),'%')
set @searchText=REPLACE(@searchText,' ', '%')

select cod_categ as cod, denumire_categ as denumire from 
categorii where
denumire_categ like '%'+ @searchtext+'%' or 
cod_categ like '%'+@searchtext+'%' 

order by 2 desc

for xml raw

