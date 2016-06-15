/****** Object:  StoredProcedure [dbo].[wUAIaUAcatpret]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAIaUAcatpret] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
set transaction isolation level READ UNCOMMITTED
declare @cod varchar(20)
select  top 100 RTRIM(categorie) as categorie,RTRIM(denumire) as denumire
from UAcatpret
for xml raw
end
