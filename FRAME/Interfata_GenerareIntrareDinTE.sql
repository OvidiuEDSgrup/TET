
delete from webconfiggrid where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('GI'='' or isnull(subtip,'')='GI')
delete from webconfigtipuri where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('GI'='' or isnull(subtip,'')='GI')
delete from webconfigform where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('GI'='' or isnull(subtip,'')='GI')
delete from webConfigTaburi where MeniuSursa='DO' and ('TE'='' or isnull(TipSursa,'')='TE')


insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','DO','TE','GI','2','Generare transfer','','','','','yso_wOPGenerareIntraredinTE','','','','','1','O','yso_wOPGenerareIntraredinTE_p',''

insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','DO','TE','GI','6','Numar transfer nou','C','@numarnou','','100','1','1','','','','',' ','','',''
union all select '','D','DO','TE','GI','10','Gest. primit.','CB','@contract','','300','1','1','wACGestiuni','','','','Selectati gestiunea primitoare','','',''
union all select '','D','DO','TE','GI','8','Data transfer nou','D','@datanoua','','100','1','1','','','','','','','',''
union all select '','D','DO','TE','GI','2','Data transfer sursa','D','@dataveche','','100','1','0','','','','','','','',''
union all select '','D','DO','TE','GI','3','Gestiune transfer sursa','CB','@gestprim','','300','1','0','wACGestiuni','','','',' ','','',''
union all select '','D','DO','TE','GI','1','Numar transfer sursa','C','@numarvechi','','100','1','0','','','','','Numar doc.','','',''