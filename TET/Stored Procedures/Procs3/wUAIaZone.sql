/****** Object:  StoredProcedure [dbo].[wUAIaZone]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAIaZone] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
set transaction isolation level READ UNCOMMITTED

 Declare  @filtrucentru varchar(8),@filtrudencentru varchar(30)
select 
   @filtrucentru = isnull(@parXML.value('(/row/@filtrucentru)[1]','varchar(8)'),''), 
   @filtrudencentru = isnull(@parXML.value('(/row/@filtrudencentru)[1]','varchar(30)'),'') 

select rtrim(a.zona) as zona,rtrim(a.denumire_zona) as denzona,
isnull(RTRIM(b.oras),'') +' Jud '+isnull(RTRIM(b.cod_judet),'')
as denlocalitate,RTRIM(a.localitate) as localitate,rtrim(a.Centru) as centru,
rtrim(d.Denumire_centru) as dencentru 
from zone a
left outer join localitati b on a.localitate=b.cod_oras 
left outer join judete c on b.cod_judet=c.cod_judet 
left outer join Centre d on d.Centru=a.centru 
WHERE   (a.centru like '%'+@filtrucentru+'%' or @filtrucentru='') 
	and (d.denumire_centru like '%'+@filtrudencentru+'%' or @filtrudencentru='')
for xml raw
end
