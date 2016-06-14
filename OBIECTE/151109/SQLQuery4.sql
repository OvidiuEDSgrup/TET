insert webConfigTipuri
select top 1 Meniu,Tip,Subtip,Ordine,Nume,Descriere,TextAdaugare,TextModificare,ProcDate,ProcScriere,ProcStergere,ProcDatePoz,ProcScrierePoz,ProcStergerePoz,Vizibil,Fel,procPopulare,tasta,ProcInchidereMacheta,detalii,publicabil 
from syssWebConfigTipuri t where t.Meniu like 't' and t.ProcDate like 'wIaTerti'
order by t.data_modificarii desc

select * -- update t set meniu='FILIALE_T'
from webConfigTipuri t where t.Meniu='T' and t.Ordine=0