-- insert webConfigTipuri
select * from webConfigSTDTipuri w where w.ProcScriere='wOPRecalculareSumeBonuri' 
OR w.procPopulare like 'wOPRecalculareSumeBonuri'
OR w.ProcScrierePoz like 'wOPRecalculareSumeBonuri'
--AND W.Tip='TE'
select * from webConfigSTDTipuri w where w.ProcScriere='wOPGenTEsauAPdinBK'
select * from webConfigSTDMeniu m where m.Meniu='EM'
select * from webConfigMeniu m where m.Meniu='EM'
select * from webConfigTipuri w where w.ProcScriere='wOPGenTEsauAPdinBK'
select * from webConfigTipuri w where w.ProcScriere='yso_wOPGenerareIntraredinTE'

-- insert webConfigForm
SELECT IdUtilizator, 'D', 'DO', 'TE', 'GI', Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil
, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip
from webConfigSTDForm f where f.TipMacheta='O' and f.Meniu='PT' 

--INSERT webconfigform
select f.* from webConfigSTDForm f join webConfigSTDTipuri w 
on w.TipMacheta=f.TipMacheta and w.Meniu=f.Meniu and w.Tip=f.Tip and w.Subtip=f.Subtip
where w.ProcScriere='wOPGenTEsauAPdinBK' AND W.Tip='TE'

select * from webConfigSTDForm f where f.Subtip='MA' and f.Tip='TE'

-- INSERT utilizatoriRIA
select 'TESTOV'
,utilizator
,parola
,utilizatorWindows
,detalii from utilizatoriRIA u where u.utilizatorWindows='TET\ASIS' and u.BD='TET'

-- INSERT bazedeDateRIA
select 'TESTOV'
,nume
,connectionStringName
,poza
,bdActiv
,detalii 
from bazedeDateRIA b where b.BD='TET'