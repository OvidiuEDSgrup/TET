
--delete from webconfiggrid where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('YW'='' or isnull(subtip,'')='YW')
--delete from webconfigtipuri where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('YW'='' or isnull(subtip,'')='YW')
--delete from webconfigform where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('YW'='' or isnull(subtip,'')='YW')
--delete from webConfigTaburi where MeniuSursa='CO' and ('BK'='' or isnull(TipSursa,'')='BK')


insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','BK','YW','8','Refacere cant.realiz','','','','','wOPRefacereCantitatiRealizate','','','','','0','O','wOPRefacereCantitatiRealizate_p',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','BK','YW','6','Comenzi livrare','CHB','@comenziLivrBK','','300','0','0','','','','','','','',''
union all select 'CO','BK','YW','12','Contract','C','@fltContract','','150','0','0','','','','','','','',''
union all select 'CO','BK','YW','2','Recalculare realizari','CHB','@recalculareRealizari','','300','0','1','','','','','','','',''
union all select 'CO','BK','YW','1','Stergere realizari','CHB','@stergereRealizari','','300','0','1','','','','','','','',''