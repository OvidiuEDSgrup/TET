--***

create procedure wIaMeniuNou @sesiune varchar(50), @parXML xml
as                
declare @limba varchar(50), @modul varchar(50), @areSuperDrept bit
/* de tratat luarea modulului din XML daca se mai foloseste */
Set @modul= isnull(@parXML.value('(/row/@modul)[1]','varchar(80)'),'')
declare @utilizator varchar(255), @doarpublicabil int 
set @doarpublicabil=0
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @limba= dbo.wfProprietateUtilizator('LIMBA',@utilizator)
set @areSuperDrept=dbo.wfAreSuperDrept(@utilizator)

select w.meniu,
	(case when max(charindex('S',w.Drepturi))>0 then 'S' else '' end)+
	(case when max(charindex('A',w.Drepturi))>0 then 'A' else '' end)+
	(case when max(charindex('M',w.Drepturi))>0 then 'M' else '' end)+
	(case when max(charindex('F',w.Drepturi))>0 then 'F' else '' end)+
	(case when max(charindex('O',w.Drepturi))>0 then 'O' else '' end)
	drepturi
into #webConfigMeniuUtiliz
from webConfigMeniuUtiliz w inner join fIaGrupeUtilizator(@utilizator) f on w.IdUtilizator=f.grupa
group by w.meniu

select 1 as '@tipnumeric',wP.nrordine as '@idmeniu', dbo.wfTradu(@limba,wP.nume) as '@nume', '' as '@icoana',
	wP.tipMacheta as '@tipMacheta', (case when @areSuperDrept=1 then 'SAMFO' else RTRIM(mu.Drepturi) end) as '@drepturi', wP.Meniu as '@codMeniu', 
( select 2 as '@tipnumeric',wC.nrordine as '@idmeniu', dbo.wfTradu(@limba,wC.nume) as '@nume', 
--(case when isnull(wC.Icoana,'')='' then wC.Nume else wC.Icoana end) 
	wC.Icoana as '@icoana',
		wC.Meniu as '@codMeniu', wC.tipMacheta as '@tipMacheta', (case when @areSuperDrept=1 then 'SAMFO' else RTRIM(mu.Drepturi) end) as '@drepturi'
	from webConfigMeniu wC
		left join #webConfigMeniuUtiliz mu on mu.meniu=wC.meniu
	where wC.meniuParinte = wP.meniu
		and (@areSuperDrept=1 or mu.meniu is not null)
		and isnull(wC.Icoana,'')!=''
		and wC.TipMacheta<>'G' --and (@doarpublicabil=0 or wC.publicabil=1)
		and wC.vizibil=1
	order by wC.nrordine
	for xml path ('row'), type
)
from webConfigMeniu wP 
	left join #webConfigMeniuUtiliz mu on mu.meniu = wP.meniu
where isnull(wP.meniuParinte,'')=''	and (@areSuperDrept=1 or isnull(mu.Meniu,'')<>'') and wp.vizibil=1
	and wp.meniu not like 'mobile%'
--	and ((@modul='' and isnull(wP.Modul,'')!='M' ) or (@modul!='' and wP.Modul=@modul))
	--and (@doarpublicabil=0 or wP.publicabil=1)
order by wP.nrordine
for xml path('row'), root('row')

if object_id('tempdb..#webConfigMeniuUtiliz') is not null drop table #webConfigMeniuUtiliz
