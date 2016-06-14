
if exists (select 1 from webconfigmeniu where tipMacheta='D' and meniu='DO') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='DO'
delete from webconfiggrid where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('GI'='' or isnull(subtip,'')='GI')
delete from webconfigtipuri where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('GI'='' or isnull(subtip,'')='GI')
delete from webconfigform where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('GI'='' or isnull(subtip,'')='GI')
insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
select top 0 null,null,null,null,null,null,null
union all select '11','Intrari/Iesiri','1','Intrari iesiri','D','DO','1'

insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','DO','TE','GI','2','Generare transfer','','','','','yso_wOPGenerareIntraredinTE','','','','','1','O',''

insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','DO','TE','GI','1','Numar transfer sursa','C','@numar','','100','1','0','','','','','Numar doc.','',''
union all select '','D','DO','TE','GI','2','Data transfer sursa','D','@data','','100','1','0','','','','','','',''
union all select '','D','DO','TE','GI','3','Gestiune transfer sursa','CB','@gestprim','','300','1','0','wACGestiuni','','','',' ','',''
union all select '','D','DO','TE','GI','4','Data transfer nou','D','@dataTE','','100','1','1','','','','','','',''
union all select '','D','DO','TE','GI','6','Gest. primit.','AC','@gestiuneprim','','300','1','1','wACGestiuni','','','','Selectati gestiunea primitoare','',''