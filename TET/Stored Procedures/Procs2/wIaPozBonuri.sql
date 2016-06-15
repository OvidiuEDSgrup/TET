--***
create procedure wIaPozBonuri @sesiune varchar(50), @parXML xml  
as    
if exists(select * from sysobjects where name='wIaPozBonuriSP' and type='P')
begin
	exec wIaPozBonuriSP @sesiune, @parXML 
	return 0
end
  
declare @Sub char(9), @tip varchar(2), @numar varchar(20), @data datetime, @vanzator varchar(10), @casam int  
  
select @Sub=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), ''),  
 @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),  
 @data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),  
 @numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''), 
 @vanzator=ISNULL(@parXML.value('(/row/@vanzator)[1]', 'varchar(100)'), ''), 
 @casam=ISNULL(@parXML.value('(/row/@casam)[1]', 'int'), 0)  
  
select (case when Factura_chitanta=1 then 'BC' else 'BY' end) as tip, (case when Factura_chitanta=1 then 'BC' else 'BY' end) as subtip,
rtrim(d.Numar_bon) as numar, convert(char(10),d.data,101) as data, 
(case when substring(d.tip,1,1)<>'3' then rtrim(d.cod_produs) else d.tip end ) as cod, 
(case when substring(d.tip,1,1)<>'3' then rtrim(isnull(n.denumire, '')) else dbo.denTipIncasare(d.tip) end ) as denumire, 
rtrim(isnull(n.UM, '')) as um,   
rtrim(isnull(antet.Factura, d.Numar_bon)) as factura, 
convert(decimal(15,2), d.Cantitate) as cantitate,
--convert(decimal(15,2),Total) as pret, 
convert(decimal(15,2),d.Total) as pret, 
convert(decimal(15,2),d.tva) as tva, 
d.Numar_document_incasare as docincas, 
(case when total <= 0 then'#FF0000' else '#000000' end)  as culoare
from bp d
left outer join nomencl n on n.cod = d.cod_produs 
inner join antetBonuri antet on antet.casa_de_marcat=d.casa_de_marcat and antet.Numar_bon=d.Numar_bon and antet.Data_bon=d.data and antet.Vinzator=d.Vinzator
left outer join terti t on t.subunitate = @Sub and t.tert = d.Client
left outer join gestiuni gPred on gPred.subunitate = @Sub and gPred.cod_gestiune = d.Loc_de_munca 
where -- d.tip='21' and 
(case when Factura_chitanta=1 then 'BC' else 'BY' end)=@tip and d.numar_bon=@numar and d.data=@data 
and d.vinzator=@vanzator and d.Casa_de_marcat = @casam 
/*and (isnull(dx.numere_pozitii, '')='' or charindex(';' + ltrim(str(p.numar_pozitie)) + ';', ';' + dx.numere_pozitii + ';')>0)*/  
/*p.subunitate = @sub and p.tip = @tip and p.numar = @numar and p.data = @data  
and (isnull(@numerepozitii, '')='' or charindex(';'+ltrim(str(p.numar_pozitie))+';', ';'+@numerepozitii+';')>0)*/  
order by d.Tip, Numar_linie DESC  
for xml raw
