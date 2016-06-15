create PROCEDURE [dbo].[wUAACTipContr]    
 @sesiune [varchar](50),    
 @parXML [xml]    
WITH EXECUTE AS CALLER    
AS    
declare @searchText varchar(100)    
select @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')    
    
select top 100 rtrim(tip) as cod,rtrim(denumire) as denumire 
from TipContracte    
where (tip like @searchText+'%' or denumire like '%'+@searchText+'%')    
order by rtrim(denumire)    
for xml raw
