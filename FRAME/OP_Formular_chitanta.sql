
delete from webconfiggrid where tipMacheta='D' and meniu='PI' and ('RE'='' or isnull(tip,'')='RE') and ('FI'='' or isnull(subtip,'')='FI')
delete from webconfigtipuri where tipMacheta='D' and meniu='PI' and ('RE'='' or isnull(tip,'')='RE') and ('FI'='' or isnull(subtip,'')='FI')
delete from webconfigform where tipMacheta='D' and meniu='PI' and ('RE'='' or isnull(tip,'')='RE') and ('FI'='' or isnull(subtip,'')='FI')
delete from webConfigTaburi where MeniuSursa='PI' and ('RE'='' or isnull(TipSursa,'')='RE')


insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','PI','RE','FI','1','Formular chitanta','','','','','wOPTemp','','','','','1','O','',''

insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','PI','RE','FI','1',' ','CHB','@formular',' ','200','1','0','','','',' ','','','',''