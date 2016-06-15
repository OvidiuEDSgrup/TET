/****** Object:  StoredProcedure [dbo].[wUAACTipurideServicii]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wUAACTipurideServicii] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(cod_serviciu) as cod,rtrim(denumire_serviciu) as denumire
from Tipuri_de_servicii
where cod_serviciu like @searchText+'%' or denumire_serviciu like '%'+@searchText+'%'
order by rtrim(denumire_serviciu)
for xml raw
