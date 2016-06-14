
/* probleme netratate la populare:
trebuie candva recreati index-ii pt. tabelele in care se face insert 
la webConfigMeniu, scriptul presupune ca folderele Documente Cataloage si Operatii au ID 1,2,3
*/

declare @webConfigTmp table (tipMacheta varchar(2), meniu varchar(2), exista bit)

begin tran 
begin try

insert into @webConfigTmp(tipMacheta, meniu, exista)
select distinct TipMacheta, Meniu, 
isnull( (select top 1 1 from webConfigMeniu w where w.TipMacheta = STD.TipMacheta
	and w.Meniu = STD.Meniu) , 0) as "exista"

from webConfigSTDMeniu STD
order by STD.TipMacheta ASC, STD.Meniu 

INSERT INTO webConfigForm(IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, 
	DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, 
	Initializare, Prompt, Procesare, Tooltip)
select 
	IdUtilizator, STD.TipMacheta, STD.Meniu, Tip, Subtip, Ordine, Nume, TipObiect, Datafield, LabelField, 
	Latime, (case when tmp.exista = 1 then 0 else STD.Vizibil end) as "vizibilNou", Modificabil,
	ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip
from webConfigSTDForm STD
inner join @webConfigTmp tmp on tmp.TipMacheta = STD.TipMacheta and tmp.Meniu = STD.Meniu
where not exists ( select 1 from webConfigForm w where
( w.IdUtilizator = STD.IdUtilizator or w.IdUtilizator is null and STD.IdUtilizator is null )
and ( w.TipMacheta = STD.TipMacheta or w.TipMacheta is null and STD.TipMacheta is null )
and ( w.Meniu = STD.Meniu or w.Meniu is null and STD.Meniu is null )
and ( w.Tip = STD.Tip or w.Tip is null and STD.Tip is null )
and ( w.Subtip = STD.Subtip or w.Subtip is null and STD.Subtip is null )
and ( w.Datafield = STD.Datafield or w.Datafield is null and STD.Datafield is null )
) 
--AND std.Meniu='CO' AND STD.Tip='BF' AND STD.Subtip='MA'

INSERT INTO webConfigFiltre(IdUtilizator, TipMacheta, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2)
select 
	IdUtilizator, STD.TipMacheta, STD.Meniu, Tip, Ordine, 
	(case when tmp.exista = 1 then 0 else STD.Vizibil end) as "vizibilNou", TipObiect, 
	Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2
from webConfigSTDFiltre STD
inner join @webConfigTmp tmp on tmp.TipMacheta = STD.TipMacheta and tmp.Meniu = STD.Meniu
where not exists ( select 1 from webConfigFiltre w where
( w.IdUtilizator = STD.IdUtilizator or w.IdUtilizator is null and STD.IdUtilizator is null )
and ( w.TipMacheta = STD.TipMacheta or w.TipMacheta is null and STD.TipMacheta is null )
and ( w.Meniu = STD.Meniu or w.Meniu is null and STD.Meniu is null )
and ( w.Tip = STD.Tip or w.Tip is null and STD.Tip is null )
and ( w.DataField1 = STD.DataField1 or w.DataField1 is null and STD.DataField1 is null )
)

--insert webConfigTaburi
--select * from webConfigSTDTaburi

INSERT INTO webConfigGrid(IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil)
select
IdUtilizator, STD.TipMacheta, STD.Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, 
(case when tmp.exista = 1 then 0 else STD.Vizibil end) as "vizibilNou"
from webConfigSTDGrid STD
inner join @webConfigTmp tmp on tmp.TipMacheta = STD.TipMacheta and tmp.Meniu = STD.Meniu
where not exists ( select 1 from webConfigGrid w where
isnull(w.IdUtilizator,'') = isnull(STD.IdUtilizator,'')
and isnull(w.TipMacheta,'') = isnull(STD.TipMacheta,'') 
and isnull(w.Meniu,'') = isnull(STD.Meniu,'') 
and isnull(w.Tip,'') = isnull(STD.Tip,'') 
and isnull(w.Subtip,'') = isnull(STD.Subtip ,'') 
and isnull(w.DataField,'') = isnull(STD.DataField ,'')
and isnull(w.InPozitii,'') = isnull(STD.InPozitii ,'')
and isnull(w.Ordine,'') = isnull(STD.Ordine,'')
)

INSERT INTO webConfigTipuri(IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, 
	TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, 
	ProcStergerePoz, Vizibil, Fel, procPopulare)
select	IdUtilizator, std.TipMacheta, std.Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare,
	TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, 
	/* std.vizibil, tmp.exista, */(case when tmp.exista = 1 then 0 else STD.Vizibil end) as "vizibilNou"
	,Fel, procPopulare
from webConfigSTDTipuri STD
inner join @webConfigTmp tmp on tmp.TipMacheta = STD.TipMacheta and tmp.Meniu = STD.Meniu
where 
not exists (select 1 from webConfigTipuri w where 
isnull(w.IdUtilizator,'') = isnull(STD.IdUtilizator,'') 
and isnull(w.TipMacheta,'') = isnull(STD.TipMacheta,'') 
and isnull(w.Meniu,'') = isnull(STD.Meniu,'') 
and isnull(w.Tip,'') = isnull(STD.Tip,'') 
and isnull(w.Subtip,'') = isnull(STD.Subtip ,'')
and isnull(w.Ordine,'') = isnull(STD.Ordine,'') )

INSERT INTO webConfigTipuri(IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, 
	TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, 
	ProcStergerePoz, Vizibil,Fel, procPopulare)
select	IdUtilizator, std.TipMacheta, std.Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare,
	TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, 
	/* std.vizibil, tmp.exista, */(case when tmp.exista = 1 then 0 else STD.Vizibil end) as "vizibilNou"
	,Fel, procPopulare
from webConfigSTDTipuri STD
inner join @webConfigTmp tmp on tmp.TipMacheta = STD.TipMacheta and tmp.Meniu = STD.Meniu
where 
not exists (select 1 from webConfigTipuri w where 
isnull(w.IdUtilizator,'') = isnull(STD.IdUtilizator,'') 
and isnull(w.TipMacheta,'') = isnull(STD.TipMacheta,'') 
and isnull(w.Meniu,'') = isnull(STD.Meniu,'') 
and isnull(w.Tip,'') = isnull(STD.Tip,'') 
and isnull(w.Subtip,'') = isnull(STD.Subtip ,'') 
and isnull(w.Ordine,'') = isnull(STD.Ordine,'') )

INSERT INTO webConfigACRapoarte(caleraport, ordine, expresie,proceduraAC)
select	caleraport, ordine, expresie,proceduraAC
from webConfigSTDACRapoarte STD
where 
not exists (select 1 from webConfigACRapoarte w where 
isnull(w.caleraport,'') = isnull(STD.caleraport,'') 
and isnull(w.ordine,'') = isnull(STD.ordine,'') 
and isnull(w.expresie,'') = isnull(STD.expresie,'') 
and isnull(w.proceduraAC,'') = isnull(STD.proceduraAC,''))

/* 
e bine ca insertul in webConfigMeniu sa se faca ultimul, pt. ca daca sunt erori la restul tabelelor, 
sa nu se populeze meniul pana ce se rezolva problema 
insertul presupune ca folderele Documente , Cataloage, Operatii au id 1, 2, respectiv 3
*/
--INSERT INTO webConfigMeniu (id, Nume, idParinte, Icoana, Meniu, Modul, TipMacheta)
--select id, Nume, idParinte, Icoana, Meniu, Modul, TipMacheta
--from 
--webConfigSTDMeniu STD
--where not exists ( select 1 from webConfigMeniu w where
--ISNULL(w.Meniu,'') = ISNULL(STD.Meniu,'')
--and ISNULL(w.TipMacheta,'') = ISNULL(STD.TipMacheta,'')
--)
--delete webConfigMeniu
INSERT INTO webConfigMeniu (id, Nume, idParinte, Icoana, Meniu, Modul, TipMacheta)
select id, Nume, idParinte, Icoana, Meniu, Modul, TipMacheta
from 
webConfigSTDMeniu STD
where not exists ( select 1 from webConfigMeniu w where
ISNULL(w.id,'') = ISNULL(STD.id,'')
and ISNULL(w.Nume,'') = ISNULL(STD.Nume,'')
and ISNULL(w.idParinte,'') = ISNULL(STD.idParinte,'')
)

 update m set icoana='pozaria'
from webConfigMeniu m where isnull(m.Icoana,'')=''

commit tran
end try
begin catch 
rollback tran
declare @msgEroare varchar(max)

set @msgEroare = error_message()

raiserror(@msgeroare, 11,1)

end catch

go


select 
1 as '@tipnumeric',wP.Id as '@idmeniu', wP.nume as '@nume', '' as '@icoana',
	wP.Modul as '@modul', wP.tipMacheta as '@tipMacheta', RTRIM(mu.Drepturi) as '@drepturi', wP.Meniu as '@codMeniu', 
( select 2 as '@tipnumeric',wC.id as '@idmeniu', wC.nume as '@nume', 
--(case when isnull(wC.Icoana,'')='' then wC.Nume else wC.Icoana end) 
	wC.Icoana as '@icoana',
		wC.Meniu as '@codMeniu', wC.modul as '@modul', wC.tipMacheta as '@tipMacheta', rtrim(mu.drepturi) as '@drepturi'
	from webConfigMeniu wC
	left join webConfigMeniuUtiliz mu on mu.idUtilizator='ASIS' and mu.idMeniu=wC.id 
	where wC.idParinte = wP.id 
	and mu.idUtilizator is not null
	--and (@modul='' or wC.Modul=@modul)
	and isnull(wC.Icoana,'')!=''
	and wC.TipMacheta<>'G' 
	order by wC.id
	for xml path ('row'), type
)
from webConfigMeniu wP 
left join webConfigMeniuUtiliz mu on mu.IdUtilizator = 'ASIS' and mu.IdMeniu = wP.Id
where wP.idParinte is null and mu.IdUtilizator is not null
--and ((@modul='' and isnull(wP.Modul,'')!='M' ) or (@modul!='' and wP.Modul=@modul))
order by wP.id

--select * from webConfigMeniuUtiliz mu where mu.IdUtilizator='ASIS' and mu.IdMeniu=550
--select * from webConfigMeniu m where m.id=550
----isnull(m.Meniu,'') ='' and isnull(m.TipMacheta,'') =''
----select * from webConfigSTDMeniu sm where sm.id=550
--go

--select * from webConfigTipuri st where st.Meniu='UE' AND st.TipMacheta='D'
----insert 
--select * from webConfigSTDTipuri st where st.Meniu='UE' AND st.TipMacheta='D'
--select * from webConfigSTDMeniu st where st.Meniu='UE' AND st.TipMacheta='D'
--select * from webConfigSTDTipuri st where st.TipMacheta='E'
--select *
---- UPDATE ST SET TIPMACHETa='D' 
--from webConfigSTDMeniu st where st.TipMacheta='E'

--select std.*
--from webConfigSTDTipuri STD
--	--inner join (select distinct TipMacheta, Meniu, 
--	--	isnull( (select top 1 1 from webConfigMeniu w where w.TipMacheta = STD.TipMacheta
--	--		and w.Meniu = STD.Meniu) , 0) as "exista"

--	--	from webConfigSTDMeniu STD) tmp 
--	--on tmp.TipMacheta = STD.TipMacheta and tmp.Meniu = STD.Meniu
--where 
--not exists (select 1 from webConfigTipuri w where 
--isnull(w.IdUtilizator,'') = isnull(STD.IdUtilizator,'') 
--and isnull(w.TipMacheta,'') = isnull(STD.TipMacheta,'') 
--and isnull(w.Meniu,'') = isnull(STD.Meniu,'') 
--and isnull(w.Tip,'') = isnull(STD.Tip,'') 
--and isnull(w.Subtip,'') = isnull(STD.Subtip ,'') 
--and isnull(w.Ordine,'') = isnull(STD.Ordine,'') )

--select * 
-- update m set icoana='pozaria'
--from webConfigMeniu m where isnull(m.Icoana,'')=''
--m.nume like '%web%'