
--if exists (select 1 from webconfigmeniu where meniu='CO') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='CO'
delete from webconfigfiltre where meniu='CO' and ('YK'='' or isnull(tip,'')='YK')
delete from webconfiggrid where meniu='CO' and ('YK'='' or isnull(tip,'')='YK') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='CO' and ('YK'='' or isnull(tip,'')='YK') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='CO' and ('YK'='' or isnull(tip,'')='YK') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='CO' and ('YK'='' or isnull(TipSursa,'')='YK')

--insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
--				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
--select top 0 null,null,null,null,null,null,null,null,null,null
--union all select 'CO','Comenzi livrare','DOCUMENTE','Contracte','D',15.00,'','','<row><vechi><row id="15" nume="Comenzi livrare" idparinte="1" icoana="Contracte" tipmacheta="D" meniu="CO" modul="3"/></vechi></row>',1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','YK','','1','Cant.aprobata','@cant_aprobata','N','120','6','1','0',''
union all select 'CO','YK','','1','Cod','@cod','C','200','1','1','0',''
union all select 'CO','YK','','1','Denumire','@denumire','C','300','2','1','0',''
union all select 'CO','YK','','1','Disc %','@discount','N','100','10','1','0',''
union all select 'CO','YK','','1','Pret vanz.f.TVA','@pretvanzare','N','125','11','1','0',''
union all select 'CO','YK','','1','Val.cu tva','@valtotala','N','150','14','1','0',''
union all select 'CO','YK','','1','Val.Tva','@valtva','N','100','13','1','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','YK','','4','Totaluri si calcule','','','','yso_wIaCon',' ','','yso_wIaPozCon','wScriuPozcon','wStergPozCon','1',' ','',''
union all select 'CO','YK','YK','1','Tot si calc pe prod','','','',' ','','','','','','1',' ','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','YK','','3','Cant.aprobata','N','@cantaprobata','','150','1','0','','','','','Cant.aprobata','','',''
union all select 'CO','YK','','1','Cant.comandata','N','@cantcomandata','','150','1','0','','','','','Cant.comandata','','',''
union all select 'CO','YK','','7','Cant.realizata','N','@cantrealizata','','150','1','0','','','','','Cant.realizata','','',''
union all select 'CO','YK','','5','Cant.transferata','N','@canttransferata','','150','1','0','','','','','Cant.transferata','','',''
union all select 'CO','YK',' ','2','Val f tva','N','@valoare','','150','1','0','','','','','Valoare','','',''
union all select 'CO','YK',' ','6','Valcutva_aprox','N','@valtotala','','150','0','0','','','','','Valoare cu tva','','',''
union all select 'CO','YK',' ','4','Tva','N','@valtva','','150','1','0','','','','','Tva','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null