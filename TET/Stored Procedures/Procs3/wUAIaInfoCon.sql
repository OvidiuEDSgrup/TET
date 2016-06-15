create PROCEDURE [dbo].[wUAIaInfoCon]  
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER
AS  
set transaction isolation level READ UNCOMMITTED  
  
 Declare  @idcontract int
select   
   @idcontract = convert(int,isnull(@parXML.value('(/row/@id_contract)[1]','int'),0))

--mod facturare,categorii pret
select top 100 rtrim(t.Denumire) as dentip,RTRIM(c.tip) as tip,convert(decimal(12,2),c.Mod_facturare) as modfacturare,
(case when c.mod_Facturare=0 then 'Manual' else (case when c.mod_Facturare=1 then 'Lunar' else (case when c.mod_Facturare=2 then '2 luni' else 
(case when c.mod_Facturare=3 then 'Trimestrial' else (case when c.mod_Facturare=4 then '4 luni' else (case when c.mod_Facturare=6 then 'Semestrial' else 
(case when c.mod_Facturare=12 then 'anual' else '?' end) end) end) end) end) end) end) as denmodfact,
c.Luna_facturare as primaluna,c.Categorie_pret as categpret,c.Ziua_de_facturare as zifacturare,
RTRIM(i.Descriere) as deninfo,RTRIM(c.info_contract) as info,c.Scadenta as scadenta,
convert(char(10),c.Data_expirarii,101) as dataexpirarii,convert(char(10),c.Data_rezilierii,101) as datarezilierii,
convert(decimal(12,0),c.categorie_penalizare) as categpen
from uacon c
left outer join TipContracte t on c.Tip=t.Tip
left outer join InfoContracte i on c.info_contract=i.Cod
where c.Id_contract=@idcontract
--order by n.denumire
for xml raw
