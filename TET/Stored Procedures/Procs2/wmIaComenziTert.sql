--***  
CREATE procedure [dbo].[wmIaComenziTert] @sesiune varchar(50), @parXML xml  
as  
set transaction isolation level READ UNCOMMITTED  

if exists(select * from sysobjects where name='wmIaComenziTertSP' and type='P')
begin
	exec wmIaComenziTertSP @sesiune, @parXML 
	return 0
end

declare @utilizator varchar(100),@subunitate varchar(9), @idpunctlivrare varchar(30), @tert varchar(30)  

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output 
if @utilizator is null 
	return -1


-- identificare tert din par xml
select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
from dbo.wmfIaDateTertDinXml(@parXML) f

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output  

select top 100 rtrim(c.Contract) as cod,   
'Comanda: '+rtrim(c.contract)+ ' din' +convert(char(10),c.data,103) as denumire,   
LTRIM(str(count(pc.cantitate)))+' pozitii: '+rtrim(convert(decimal(12,2),sum(pc.Cantitate*pc.Pret*(1-pc.discount/100))))+' LEI'  as info  
from con c  
left outer join pozcon pc on c.Subunitate=pc.Subunitate and c.Tip=pc.Tip and c.Tert=pc.Tert and c.Contract=pc.Contract  
left outer join terti t on c.Tert=t.Tert  
where c.subunitate=@subunitate and c.Tip='BK' and c.Responsabil=@utilizator and c.tert=@tert
--and c.Stare=(select rtrim(val_alfanumerica) from par where tip_parametru='UC' and parametru='STAREBK0')
group by c.Subunitate,c.Tip,c.Tert,c.Contract,c.Explicatii,t.Denumire, c.data
union all  
select top 100 '<NOU>' as cod,   
'<Comanda noua>' as denumire,
'' as info  
order by 1  
for xml raw  
 
 /*
 
 De unde va fi apelata se vor trimite detaliile
   
 select 'Comenzi deschise' as titlu,'wmDetComenziTert' as detalii,0 as areSearch  
 for xml raw,Root('Mesaje')   
 */
