--***
CREATE procedure [dbo].[wmIaVanzari] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmIaVanzariSP' and type='P')
begin
	exec wmIaVanzariSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED
declare @dataold datetime
set @dataold=DATEADD(month,-2,getdate())

select top 20 --CONVERT(char(10),bp.data,120)+'|'+ltrim(str(bp.Casa_de_marcat)) as cod, 
	CONVERT(char(10),p.data,120) data, p.gestiune as gestiune, 
	CONVERT(char(10),p.data,103)+':'+rtrim(left(g.Denumire_gestiune,30)) as denumire,
	ltrim(str(count(distinct Numar)))+' doc., in valoare de '+
	ltrim(convert(varchar(20),convert(money,sum(p.Cantitate*p.Pret_vanzare+p.TVA_deductibil)),1))+
	' lei'
	 as info
from pozdoc p
left outer join gestiuni g on p.Gestiune=g.Cod_gestiune
where p.Subunitate='1' and p.tip in ('AP','AC','AS') and p.data>@dataold
group by p.data,g.Denumire_gestiune, p.gestiune
order by p.data desc,g.Denumire_gestiune, p.gestiune
for xml raw

select 'Vanzari' as titlu,'wmDetVanzari' as detalii,0 as areSearch, 1 toateAtr
for xml raw,Root('Mesaje')
