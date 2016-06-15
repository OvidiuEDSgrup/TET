CREATE PROCEDURE  [yso].[wACValProprietatiTerti] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @searchText varchar(100),@codprop varchar(20)
set @searchText=isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%')
set @codprop=isnull(@parXML.value('(/row/@codprop)[1]','varchar(20)'),'')
set @searchText='%'+rtrim(ltrim(REPLACE(@searchText, ' ', '%')))+'%'

select top 100 rtrim(valoare) as cod,rtrim(descriere) as denumire
from valproprietati  
where cod_proprietate=@codprop and 
(RTRIM(valoare) like rtrim(@searchText) or rtrim(descriere) like rtrim(@searchText))
order by valoare
for xml raw
