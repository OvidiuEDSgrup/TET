--***
create procedure wmDetVanzari @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmDetVanzariSP' and type='P')
begin
	exec wmDetVanzariSP @sesiune, @parXML 
	return -1
end

declare @data datetime,@gestiune varchar(20), @utilizator varchar(50)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null 
	return -1

select 	@data=@parXML.value('(/row/@data)[1]','datetime'),
		@gestiune=@parXML.value('(/row/@gestiune)[1]','varchar(10)')

select top 100 ltrim(str(p.numar)) as cod, 
	'Client: '+ltrim(isnull(t.denumire,'Persoana fizica')) as denumire,ltrim(p.numar) as numar,@gestiune gestiune,
	ltrim(str(count(*)))+' '+(case when count(*)=1 then 'pozitie' else 'pozitii' end)+', valoare '+
	ltrim(convert(varchar(20),convert(money,sum(p.Cantitate*p.Pret_vanzare+p.TVA_deductibil)),1))+
	' lei' as info,
	'@nrbon' numeatr
from pozdoc p
left outer join terti t on p.tert=t.tert
where p.subunitate='1' and p.tip in ('AP','AC','AS') and p.data=@data and p.gestiune=@gestiune
group by p.Numar,t.denumire
order by p.numar desc
for xml raw

select 'Vanzari din :'+convert(char(10),@data,103) as titlu,'wmAfiseazaVanzari' as detalii,0 as areSearch,1 toateAtr
for xml raw,Root('Mesaje')
