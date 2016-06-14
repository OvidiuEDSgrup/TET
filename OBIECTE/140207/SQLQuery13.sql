
--if exists (select 1 from webconfigmeniu where meniu='T') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='C' and meniu='T'
delete from webconfigfiltre where meniu='T' and ('PC'='' or isnull(tip,'')='PC')
delete from webconfiggrid where meniu='T' and ('PC'='' or isnull(tip,'')='PC') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='T' and ('PC'='' or isnull(tip,'')='PC') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='T' and ('PC'='' or isnull(tip,'')='PC') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='T' and ('PC'='' or isnull(TipSursa,'')='PC')



insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'T','PC','','0','Apartament','@apartament','N','100','21','0','0',''
union all select 'T','PC','','0','Bloc','@bloc','C','150','19','0','0',''
union all select 'T','PC','','0','Cod postal','@codpostal','N','150','24','0','0',''
union all select 'T','PC','','0','Data nasterii','@datanasterii','D','100','25','0','0',''
union all select 'T','PC','','0','Den. tert','@dentert','C','150','2','0','0',''
union all select 'T','PC','','0','Descriere','@descriere','C','200','4','1','0',''
union all select 'T','PC','','0','Eliberat','@eliberatbuletin','C','150','10','0','0',''
union all select 'T','PC','','0','Email','@email','C','300','15','0','0',''
union all select 'T','PC','','0','Functie','@functie','C','150','11','0','0',''
union all select 'T','PC','','0','Identificator','@identificator','C','150','3','0','0',''
union all select 'T','PC','','0','Cont','@info1','C','200','17','0','0',''
union all select 'T','PC','','0','Cont','@info2','C','200','22','0','0',''
union all select 'T','PC','','0','Loc munca','@info3','C','150','5','0','0',''
union all select 'T','PC','','0','Indicator','@info4','C','200','23','0','0',''
union all select 'T','PC','','0','Info5','@info5','C','100','26','0','0',''
union all select 'T','PC','','0','Info6','@info6','N','150','27','0','0',''
union all select 'T','PC','','0','Info7','@info7','C','200','28','0','0',''
union all select 'T','PC','','0','Judet','@judet','C','150','12','1','0',''
union all select 'T','PC','','0','Localitate','@localitate','C','150','13','1','0',''
union all select 'T','PC','','0','Numar','@numar','N','100','18','0','0',''
union all select 'T','PC','','0','Numar buletin','@numarbuletin','C','150','9','0','0',''
union all select 'T','PC','','0','Nume','@nume','C','150','6','1','0',''
union all select 'T','PC','','0','Prenume','@prenume','C','200','7','1','0',''
union all select 'T','PC','','0','Scara','@scara','C','150','20','0','0',''
union all select 'T','PC','','0','Serie buletin','@seriebuletin','C','100','8','0','0',''
union all select 'T','PC','','0','Strada','@strada','C','200','16','0','0',''
union all select 'T','PC','','0','Telefon','@telefon','C','150','14','0','0',''
union all select 'T','PC','','0','Tert','@tert','C','150','1','0','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'T','PC','','1','Persoane contact','','Adaugare persoana','','wIaPersoaneContact','wScriuPersoaneContact','wStergPersoaneContact',' ',' ',' ','1','','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'T','PC','','4','Adresa','C','@email','','200','1','1','','','','','','','',''
union all select 'T','PC','','10','Observatii','C','@info7','','300','1','1','','','','','','','',''
union all select 'T','PC',' ','3','Judet','AC','@judet','@judet','200','1','1','wACJudete','','','','Judet','','',''
union all select 'T','PC','','4','Localitate','C','@localitate','','200','1','1','','','','','Localitate','','',''
union all select 'T','PC','','1','Nume','C','@nume','','300','1','1','','','','','','','',''
union all select 'T','PC','','2','Prenume','C','@prenume','','300','1','1','','','','','','','',''
union all select 'T','PC','','7','Telefon','C','@telefon','','150','1','1','','','','','Telefon','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null