/*
if exists (select 1 from webconfigmeniu where tipMacheta='D' and meniu='DO') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--*/delete from webconfigmeniu where tipMacheta='D' and meniu='DO'
delete from webconfiggrid where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('CT'='' or isnull(subtip,'')='CT')
delete from webconfigtipuri where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('CT'='' or isnull(subtip,'')='CT')
delete from webconfigform where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('CT'='' or isnull(subtip,'')='CT')
insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
select top 0 null,null,null,null,null,null,null
union all select '11','Intrari/Iesiri','1','Intrari iesiri','D','DO','1'

insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','DO','TE','CT','1','Cod','@cod','C','70','1','0'
union all select '','D','DO','TE','CT','1','Cod','@cod','C','70','1','0'
union all select '','D','DO','TE','CT','1','Denumire','@denumire','C','300','2','0'
union all select '','D','DO','TE','CT','1','Cant. transferata','@cant_transferata','N','100','3','0'
union all select '','D','DO','TE','CT','1','Cant. disponibila','@cant_disponibila','N','100','4','0'
union all select '','D','DO','TE','CT','1','Pret amanunt','@pamanunt','N','100','5','0'
union all select '','D','DO','TE','CT','1','Cant. de transferat','@cantitate','N','100','5','0'

insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','DO','TE','CT','2','Completare transfer','','','','','yso_wOPGenerareIntraredinTE','','','','','1','O',''

insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','DO','TE','CT','1','Numar transfer','C','@numar','','100','1','0','','','','','Numar doc.','',''
union all select '','D','DO','TE','CT','2','Data transfer','D','@data','','100','1','0','','','','','','',''
union all select '','D','DO','TE','CT','3','Gestiune predatoare ','CB','@gestiune','@dengestiune','300','1','0','wACGestiuni','','','',' ','',''
union all select '','D','DO','TE','CT','4','Gestiune primitoare','AC','@gestprim','@dengestprim','300','1','0','wACGestiuni','','','','Selectati gestiunea primitoare','',''