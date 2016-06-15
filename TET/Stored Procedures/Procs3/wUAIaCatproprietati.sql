--***
/****** Object:  StoredProcedure [dbo].[wUAIaCatproprietati]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE [dbo].[wUAIaCatproprietati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
set transaction isolation level READ UNCOMMITTED
select rtrim(cod_proprietate) as codproprietate,rtrim(descriere) as descriere
, rtrim(case when validare=0 then 'Fara validare' when validare=1 then 'Lista' when Validare=2 then 'Catalog' else 'Compusa' end) as validare,
catalog as catalog,rtrim(case when catalog='1' then 'Nomenclator abonati' when catalog='2' then 'Abonati' when catalog='3' then 'Contracte' 
when catalog='4' then 'Casieri' when catalog='5' then 'Zone' when catalog='6' then 'Centre' else '' end) as denumire,
RTRIM(proprietate_parinte) as proprietateparinte
from catproprietati
order by cod_proprietate,descriere
for xml raw
end
