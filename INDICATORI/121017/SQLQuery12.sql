--***  
Create procedure wIaStocuriNomenclator   @sesiune varchar(30), @parXML XML  
as  
if exists(select * from sysobjects where name='wIaStocuriNomenclatorSP' and type='P')  
 exec wIaStocuriNomenclatorSP @sesiune, @parXML   
else        
begin  
  
Declare @iDoc int  
  
Declare @cSub varchar(9), @cod varchar(20)  
exec luare_date_par 'GE','SUBPRO',1,0,@cSub OUTPUT  
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')  
  
  
select  rtrim(s.tip_gestiune) as tip, rtrim(s.cod_gestiune) as gestiune, convert(decimal(15,5),s.pret) as pret,  
convert(char(10),s.data,101) as data, convert(decimal(12,3),s.stoc) as stoc, RTRIM(s.cont) as cont, RTRIM(s.cod_intrare) as codintrare ,  
rtrim(s.cod_gestiune)+'-'+RTRIM(g.Denumire_gestiune) as dengestiune  
from stocuri s  
inner join gestiuni g on s.Cod_gestiune=g.Cod_gestiune  
where s.Subunitate = @cSub and s.Cod = @cod and s.Stoc <> 0  
order by s.Data  
for xml raw  
end