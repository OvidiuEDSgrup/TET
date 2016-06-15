/****** Object:  StoredProcedure [dbo].[wUAACDocfiscale]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAACDocfiscale] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 id as cod,(case when tipdoc='UC' then 'Contracte UA' else
 (case when tipdoc='UF' then 'Facturi UA' else (case when TipDoc='UI' then 'IncasariUA' else 'Compensari UA' end) end) end )
 +' Serie '+rtrim(serie) +' Nr inf '+rtrim(Numarinf ) +' Nr sup '+rtrim(Numarsup ) +' Ultimul nr '+rtrim(UltimulNr ) as denumire
from docfiscale where TipDoc in ('UC','UF','UI','UP') order by tipdoc
for xml raw
