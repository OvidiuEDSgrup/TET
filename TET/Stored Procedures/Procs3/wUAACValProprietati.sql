/****** Object:  StoredProcedure [dbo].[wUAACValProprietati]    Script Date: 01/05/2011 23:51:25 ******/
--***

Create  PROCEDURE  [dbo].[wUAACValProprietati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @searchText varchar(100),@codproprietate varchar(20)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')
set @codproprietate=replace(isnull(@parXML.value('(/row/@codproprietate)[1]','varchar(20)'),'%'),' ','%')

select top 100 rtrim(valoare) as cod,rtrim(descriere) as denumire
from valproprietati  
where cod_proprietate=@codproprietate and 
(valoare like @searchText+'%' or descriere like '%'+@searchText+'%')
order by valoare
for xml raw
