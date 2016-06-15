--***
CREATE procedure [dbo].[wmAfiseazaVanzari] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmAfiseazaVanzariSP' and type='P')
begin
	exec wmAfiseazaVanzariSP @sesiune, @parXML 
	return -1
end

declare @numar varchar(20),@gestiune varchar(20),@data datetime
select 	@numar=@parXML.value('(/row/@numar)[1]','varchar(20)'),
		@data=@parXML.value('(/row/@data)[1]','datetime'),
		@gestiune=@parXML.value('(/row/@gestiune)[1]','varchar(20)')
		
select top 100 rtrim(n.denumire) as cod, 
rtrim(n.denumire) as denumire,
LTRIM(str(p.Cantitate))+' '+RTRIM(n.UM)+' x '+LTRIM(str((p.cantitate*p.Pret_vanzare+p.tva_deductibil)/p.cantitate))+' lei = '+
convert(varchar(20),convert(money,p.Cantitate*p.Pret_vanzare+p.TVA_deductibil,1))+
	' lei' as info
from pozdoc p
inner join nomencl n on p.Cod=n.Cod
where p.subunitate='1' and p.tip in ('AP','AC','AS') and p.data=@data and p.gestiune=@gestiune and p.numar=@numar
order by 1 desc
for xml raw

select 'Doc:'+@numar+' din:'+convert(char(10),@data,103) as titlu,0 as areSearch
for xml raw,Root('Mesaje')
