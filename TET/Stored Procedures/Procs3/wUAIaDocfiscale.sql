/****** Object:  StoredProcedure [dbo].[wUAIaDocfiscale]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAIaDocfiscale]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
set transaction isolation level READ UNCOMMITTED

select rtrim(a.id) as id,rtrim(a.tipdoc) as tipdoc,RTRIM(a.serie) as serie, 
rtrim(a.numarinf) as numarinf, RTRIM(a.numarsup) as numarsup,RTRIM(ultimulNr) as ultimulnr
from docfiscale a 
where tipdoc in ('UC','UF','UI','UP')
order by a.tipdoc 
for xml raw
