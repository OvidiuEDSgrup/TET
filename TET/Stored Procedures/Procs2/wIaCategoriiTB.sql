--***


/* Procedura apartine machetei de TB ( vizualizare date ) */
/* Aceasi procedura apartine si in ASiSmobile*/
CREATE procedure  wIaCategoriiTB  @sesiune varchar(50), @parXML XML 
as 
set transaction isolation level read uncommitted

if exists (select 1 from sysobjects where [type]='P' and [name]='wIaCategoriiTBSP')
begin
	exec wIaCategoriiTBSP @sesiune, @parXML output
	return
end

select  rtrim(c.Cod_categ) as cod,rtrim(c.Denumire_categ) as denumire,
ltrim(str(isnull((select COUNT(*) from compcategorii  where cod_categ=c.cod_categ),0)))+' indicatori' as info
from categorii c 
where categ_tb>0
order by categ_tb
for xml raw

select 'wIaIndicatoriMobile' as detalii,0 as areSearch, '@categorie' _numeAtr
for xml raw,Root('Mesaje')
