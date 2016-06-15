--***
Create PROCEDURE [dbo].[wUAACFormulare]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')
select top 100 rtrim(Numar_formular) as cod,rtrim(denumire_formular) as denumire
from AntForm WHERE Tip_formular='U'
order by denumire_formular
for xml raw
