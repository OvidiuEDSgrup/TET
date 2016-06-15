--***
CREATE procedure [dbo].[wmIaBonuri] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmIaBonuriSP' and type='P')
begin
	exec wmIaBonuriSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED
declare @dataold datetime
set @dataold=DATEADD(month,-2,getdate())

select top 20 CONVERT(char(10),bp.data,103)+'|'+ltrim(bp.Loc_de_munca) as cod, 
CONVERT(char(10),bp.data,103)+' '+bp.Loc_de_munca as denumire,
ltrim(str(count(distinct numar_bon)))+' bonuri, in valoare de '+
	ltrim(convert(varchar(20),convert(money,sum(convert(decimal(15,2), bp.Total))),1))+' lei' as info
from bp
where bp.Tip='21' and data>@dataold
group by bp.data,bp.Loc_de_munca,bp.Casa_de_marcat
order by bp.data desc,bp.Casa_de_marcat
for xml raw

select 'Bonuri' as titlu,'wmDetBonuri' as detalii,0 as areSearch
for xml raw,Root('Mesaje')
