/****** Object:  StoredProcedure [dbo].[wUAACProprietati]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAACProprietati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @searchText varchar(100),@codmeniu varchar(2)
 select
  @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%'),
  @codmeniu=replace(isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(2)'),'%'),' ','%')

select top 100 rtrim(cod_proprietate) as cod,rtrim(descriere) as denumire,(case when Catalog ='1' then 'Nomenclator' when Catalog='2' then 'Abonati' 
when   Catalog='3' then 'Contract' when Catalog='4' then 'Casieri'  when Catalog='5' then 'Zone' when  Catalog='6' then 'Centre' else '' end) as info
from catproprietati
where (cod_proprietate like @searchText+'%' or descriere like '%'+@searchText+'%')
order by cod_proprietate
for xml raw
