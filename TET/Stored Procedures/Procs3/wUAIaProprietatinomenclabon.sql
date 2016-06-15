/****** Object:  StoredProcedure [dbo].[wUAIaProprietatinomenclabon]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAIaProprietatinomenclabon] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
set transaction isolation level READ UNCOMMITTED
declare @cod varchar(20)

select 
	   @cod=isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), '')
	 
select  top 100 RTRIM(a.cod) as cod,RTRIM(a.cod_proprietate) as codproprietate,RTRIM(a.valoare) as valoare,RTRIM(b.descriere) as denc,
RTRIM(c.descriere) as denv
from proprietati a
left outer join catproprietati b on a.Cod_proprietate=b.cod_proprietate and a.tip=b.catalog
left outer join valproprietati c on a.Cod_proprietate=c.cod_proprietate and a.Valoare=c.valoare 
where a.cod = @cod
for xml raw
end
