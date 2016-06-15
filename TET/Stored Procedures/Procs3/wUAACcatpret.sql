/****** Object:  StoredProcedure [dbo].[wUAACcatpret]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAACcatpret] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(categorie) as cod,rtrim(categorie)+'-'+rtrim(denumire) as denumire
from UAcatpret
where categorie like @searchText+'%' or denumire like '%'+@searchText+'%'
order by rtrim(denumire)
for xml raw
--select * from uacatpret
