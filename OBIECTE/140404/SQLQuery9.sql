
delete from webconfiggrid where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('IB'='' or isnull(subtip,'')='IB')
delete from webconfigtipuri where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('IB'='' or isnull(subtip,'')='IB')
delete from webconfigform where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('IB'='' or isnull(subtip,'')='IB')
--delete from webConfigTaburi where MeniuSursa='DO' and ('AP'='' or isnull(TipSursa,'')='AP')


insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AP','IB','60','Incasare factura','','','','','wOPIncasare','','','','','1','O','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AP','IB','1','Numar chitanta','C','@chitanta','','100','1','1','','','','','','','',''
union all select 'DO','AP','IB','4','Cont casa','AC','@contcasa','@contcasa','200','1','1','wACConturi','','','','','','',''
union all select 'DO','AP','IB','10','Formular:','AC','@formular','@denFormular','300','1','1','wACFormulare','','','','Alegeti formularul pentru chitanta','','',''
union all select 'DO','AP','IB','9','Generare formular','CHB','@generare','','300','1','1','','','','','','','',''
union all select 'DO','AP','IB','2','Suma LEI','N','@sumalei','','200','1','1','','','','','','','',''
union all select 'DO','AP','IB','3','Suma valuta','N','@sumavaluta','','200','0','1','','','','','','','',''