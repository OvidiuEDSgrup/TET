/****** Object:  StoredProcedure [dbo].[wUAIaProprietaticasieri]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAIaProprietaticasieri] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
set transaction isolation level READ UNCOMMITTED
declare @codcasier varchar(10)

select 
	   @codcasier=isnull(@parXML.value('(/row/@codcasier)[1]', 'varchar(8)'), '')
	 
select  top 100 RTRIM(a.cod) as cod,RTRIM(a.cod_proprietate) as codproprietate,RTRIM(a.valoare) as valoare,
RTRIM(b.descriere) as denc,RTRIM(c.descriere) as denv
from proprietati a
left outer join catproprietati b on a.Cod_proprietate=b.cod_proprietate and a.tip=b.catalog
left outer join valproprietati c on a.Cod_proprietate=c.cod_proprietate and a.Valoare=c.valoare 
where a.cod = @codcasier
for xml raw
end
