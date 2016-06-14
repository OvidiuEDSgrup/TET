delete from webconfigmeniu where tipMacheta='C' and meniu='TD'
delete from webconfigfiltre where tipMacheta='C' and meniu='TD' and (''='' or isnull(tip,'')='')
delete from webconfiggrid where tipMacheta='C' and meniu='TD' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where tipMacheta='C' and meniu='TD' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where tipMacheta='C' and meniu='TD' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')

----------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
select top 0 null,null,null,null,null,null,null
union all select '559','Tipuri documente','550','utilaje','C','TD','ED'


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select '','C','TD','','','0','Tip document','@tip','C','150','1','1'
union all select '','C','TD','','','0','Denumire','@denumire','C','250','2','1'


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigFiltre (IdUtilizator, TipMacheta, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','C','TD','TD','1','1','','Tip document','Tip document','@f_tip','0','',''
union all select '','C','TD','TD','2','1','','Denumire','Denumire','@f_denumire','0','',''


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','C','TD','','','1','Tipuri documente','','Adaugare tip document','Modificare tip document','wIaTipuriDoc','wScriuTipuriDoc','wStergTipuriDoc','','','','1',' ',''


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','C','TD','','','1','Tip document','C','@tip','','100','1','1','','','','','Tip','',''
union all select '','C','TD','','','2','Denumire','C','@denumire','','200','1','1','','','','','Denumire','',''

