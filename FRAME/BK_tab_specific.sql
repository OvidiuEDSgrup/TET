
if exists (select 1 from webconfigtipuri where tipMacheta='D' and meniu='KO' and tip='YK') begin raiserror('Acest tip este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
/*
delete from webconfigmeniu where tipMacheta='D' and meniu='KO'
insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
select top 0 null,null,null,null,null,null,null
union all select '15','Contracte','1','Contracte','D','KO','3'
*/
delete from webconfiggrid where tipMacheta='D' and meniu='KO' and ('YK'='' or isnull(tip,'')='YK')
delete from webconfigfiltre where tipMacheta='D' and meniu='KO' and ('YK'='' or isnull(tip,'')='YK')
delete from webconfigtipuri where tipMacheta='D' and meniu='KO' and ('YK'='' or isnull(tip,'')='YK')
delete from webconfigform where tipMacheta='D' and meniu='KO' and ('YK'='' or isnull(tip,'')='YK')


insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','KO','YK','','1','Val.Tva','@valtva','N','100','13','1'
union all select '','D','KO','YK','','1','Val.cu tva','@valtotala','N','150','14','1'
union all select '','D','KO','YK','','1','Pret vanz.f.TVA','@pretvanzare','N','125','11','1'
union all select '','D','KO','YK','','1','Denumire','@denumire','C','300','2','1'
union all select '','D','KO','YK','','1','Cod','@cod','C','200','1','1'
union all select '','D','KO','YK','','1','Cant.aprobata','@cant_aprobata','N','120','6','1'
union all select '','D','KO','YK','','1','Disc %','@discount','N','100','10','1'

insert into webconfigFiltre (IdUtilizator, TipMacheta, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','KO','YK','','4','Totaluri si calcule','','','','yso_wIaCon','','','yso_wIaPozCon','','','1',' ',''
union all select '','D','KO','YK','YK','1','Tot si calc pe prod','','','',' ','','','','','','1',' ',''

insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','KO','YK',' ','21','Val f tva','N','@valoare','','150','1','0','','','','','Valoare','',''
union all select '','D','KO','YK',' ','23','Tva','N','@valtva','','150','1','0','','','','','Tva','',''
union all select '','D','KO','YK',' ','22','Val. cu tva','N','@valtotala','','150','1','0','','','','','Valoare cu tva','',''
union all select '','D','KO','YK','','1','Cant.comandata','N','@cantcomandata','','150','1','0','','','','','Cant.comandata','',''
union all select '','D','KO','YK','','2','Cant.aprobata','N','@cantaprobata','','150','1','0','','','','','Cant.aprobata','',''
union all select '','D','KO','YK','','3','Cant.transferata','N','@canttransferata','','150','1','0','','','','','Cant.transferata','',''
union all select '','D','KO','YK','','4','Cant.realizata','N','@cantrealizata','','150','1','0','','','','','Cant.realizata','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'KO','BK','Comenzi livrare','','PozDoc','KO','BK','','10','1'
union all select 'KO','BK','Totaluri si calcule','','PozDoc','KO','YK','','20','1'