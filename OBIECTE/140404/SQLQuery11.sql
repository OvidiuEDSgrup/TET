
delete from webconfiggrid where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('AI'='' or isnull(subtip,'')='AI')
delete from webconfigtipuri where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('AI'='' or isnull(subtip,'')='AI')
delete from webconfigform where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('AI'='' or isnull(subtip,'')='AI')
--delete from webConfigTaburi where MeniuSursa='DO' and ('AP'='' or isnull(TipSursa,'')='AP')


insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null