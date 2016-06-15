/****** Object:  StoredProcedure [dbo].[wUAIaProprietatiabonati]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wUAIaProprietatiabonati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
set transaction isolation level READ UNCOMMITTED
declare @codabonat varchar(13)

select 
	   @codabonat=isnull(@parXML.value('(/row/@codabonat)[1]', 'varchar(13)'), '')
	 
select  top 100 RTRIM(a.cod) as cod,RTRIM(a.cod_proprietate) as codproprietate,RTRIM(a.valoare) as valoare,RTRIM(b.descriere) as denc,RTRIM(c.descriere) as denv
from proprietati a
left outer join catproprietati b on a.Cod_proprietate=b.cod_proprietate and a.tip=b.catalog
left outer join valproprietati c on a.Cod_proprietate=c.cod_proprietate and a.Valoare=c.valoare
where a.cod = @codabonat
for xml raw
end
