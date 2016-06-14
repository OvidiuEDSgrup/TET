--/*
if exists (select 1 from webconfigmeniu where tipMacheta='D' and meniu='DO') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--*/delete from webconfigmeniu where tipMacheta='D' and meniu='DO'
delete from webconfiggrid where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('CT'='' or isnull(subtip,'')='CT')
delete from webconfigtipuri where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('CT'='' or isnull(subtip,'')='CT')
delete from webconfigform where tipMacheta='D' and meniu='DO' and ('TE'='' or isnull(tip,'')='TE') and ('CT'='' or isnull(subtip,'')='CT')
insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
select top 0 null,null,null,null,null,null,null
union all select '42','Comenzi terti','7','Comenzi','D','DO','UC'

insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','DO','TE','CT','1','Cod','@cod','C','70','1','0'
union all select '','D','DO','TE','CT','1','Denumire','@denumire','C','300','2','0'
union all select '','D','DO','TE','CT','1','Cant. aprobata','@cant_aprobata','N','100','3','0'
union all select '','D','DO','TE','CT','1','Cant. transferata','@cant_transferata','N','100','4','0'
union all select '','D','DO','TE','CT','1','Cant. disponibila','@cantitate_disponibila','N','100','5','0'
union all select '','D','DO','TE','CT','1','Cant. de transferat','@cantitate_transfer','N','100','6','0'

insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','DO','TE','CT','1','Generare document','Operatie care va genera document de tip TE din comenzi de livrare. Data aleasa va fi data documentului care va fi generat','','','','wOPGenTEsauAPdinBK','','','','','1','O',''

insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','DO','TE','CT','1','Numar transfer','C','@numardoc','','100','0','1','','','','','Numar transfer','',''
union all select '','D','DO','TE','CT','1','Nume delegat','C','@numedelegat','','100','1','1','','','','','Nume delegat','',''
union all select '','D','DO','TE','CT','2','Numar mijl transport','C','@nrmijltransp','','100','1','1','','','','','Nr mijloc de transport','',''
union all select '','D','DO','TE','CT','3','Observatii','C','@observatii','','100','1','1','','','','','Observatii','',''
union all select '','D','DO','TE','CT','4','Gestiune transp.','AC','@gesttr','@dengestiune','200','1','1','wACGestiuniD','','','','Gestiune transp','',''
union all select '','D','DO','TE','CT','5','Data','D','@datadoc','','100','1','1','','','','','','',''
union all select '','D','DO','TE','CT','5','Mijloc de transport','C','@mijloctp','','150','0','1','','','','','Mijloc de transport','',''
union all select '','D','DO','TE','CT','7','Serie Buletin','C','@seriabuletin','','150','0','1','','','','','','',''
union all select '','D','DO','TE','CT','8','Numar Buletin','C','@numarbuletin','','100','0','1','','','','','','',''
union all select '','D','DO','TE','CT','9','Eliberat','C','@eliberat','','150','0','1','','','','','','',''