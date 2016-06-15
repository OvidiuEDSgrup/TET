/****** Object:  StoredProcedure [dbo].[wUAIaValproprietati]    Script Date: 01/05/2011 23:51:25 ******/
--***

Create PROCEDURE  [dbo].[wUAIaValproprietati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
set transaction isolation level READ UNCOMMITTED

declare @codproprietate varchar(20)

select @codproprietate=isnull(@parXML.value('(/row/@codproprietate)[1]', 'varchar(20)'), '')

select Top 100 RTRIM(a.valoare) as valoare,RTRIM(a.descriere) as descriere
from valproprietati a
where cod_proprietate=@codproprietate
order by a.valoare


for xml raw
end
