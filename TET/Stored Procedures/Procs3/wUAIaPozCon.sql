create PROCEDURE [dbo].[wUAIaPozCon]    
 @sesiune [varchar](50),    
 @parXML [xml]    
WITH EXECUTE AS CALLER  
AS    
set transaction isolation level READ UNCOMMITTED    
    
 Declare  @idcontract int  
select     
   @idcontract = convert(int,isnull(@parXML.value('(/row/@id_contract)[1]','int'),0))  
  
select top 100 p.Id_contract,rtrim(p.cod) as cod,RTRIM(n.Denumire) as serviciu,  
CONVERT(decimal(12,2),p.Cantitate) as cantitate,CONVERT(decimal(12,2),p.pret) as pret,RTRIM(n.um) as um,  
p.Numar_pozitie as numar_pozitie,CONVERT(decimal(12,2),n.tarif) as pret_nomencl  
from uacon c,uapozcon p,NomenclAbon n  
where c.Id_contract=p.Id_contract and p.Cod=n.cod and p.Id_contract=@idcontract  
order by n.denumire  
for xml raw
