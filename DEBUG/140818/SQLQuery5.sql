
----if exists (select 1 from webconfigmeniu where meniu='G') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='C' and meniu='G'
delete from webconfigfiltre where meniu='G' and (''='' or isnull(tip,'')='')
delete from webconfiggrid where meniu='G' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='G' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='G' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='G' and (''='' or isnull(TipSursa,'')='')

--insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
--				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
--select top 0 null,null,null,null,null,null,null,null,null,null
--union all select 'G','Gestiuni','CATALOAGE','Gestiuni','C',25.00,'','','<row><vechi><row id="25" nume="Gestiuni" idparinte="2" icoana="Gestiuni" tipmacheta="C" meniu="G" modul=" " publicabil="1"/></vechi></row>',1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'G','','','0','Cont','@cont','C','40','7','1','0',''
union all select 'G','','','0','Denumire cont','@dencont','C','150','8','0','0',''
union all select 'G','','','0','Denumire gestiune','@dengestiune','C','150','2','1','0',''
union all select 'G','','','0','Loc de munca','@denlm','C','150','9','1','0',''
union all select 'G','','','0','Denumire tert','@dentert','C','150','6','1','0',''
union all select 'G','','','0','Denumire tip','@dentipgestiune','C','150','4','0','0',''
union all select 'G','','','0','Gestiune','@gestiune','C','40','1','1','0',''
union all select 'G','','','0','Tert','@tert','C','40','5','1','0',''
union all select 'G','','','0','Tip','@tipgestiune','C','20','3','1','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'G','G','6','1','','Cont','Cont','@cont','0','',''
union all select 'G','G','7','0','','Denumire cont','Denumire cont','@dencont','0','',''
union all select 'G','G','5','1','','Denumire tert','Denumire tert','@dentert','0','',''
union all select 'G','G','2','1','','Denumire','Denumire','@denumire','0','',''
union all select 'G','G','1','1','','Gestiune','Gestiune','@gestiune','0','',''
union all select 'G','G','4','1','','Tert','Tert','@tert','0','',''
union all select 'G','G','3','1','','Tip','Tip gestiune','@tipgestiune','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'G','','','0','Gestiuni',' ','Adaugare gestiune','Modificare gestiune','wIaGestiuni','wScriuGestiuni','wStergGestiuni','','','','0','','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'G','','','5','Cont','AC','@cont','@dencont','150','1','1','wACConturi','','','','Cont','','Cont',''
union all select 'G','','','2','Denumire','C','@dengestiune','','200','1','1','','','','','Denumire','','Denumire',''
union all select 'G','','','7','Custodie','CB','@detalii_custodie','@detalii_dencustodie','200','1','1','','1,0','Da,Nu','0','','','',''
union all select 'G','','','1','Gestiune','C','@gestiune','@dengestiune','100','1','1','','','','','Gestiune','','Gestiune',''
union all select 'G','','','6','Loc de munca','AC','@lm','@denlm','200','1','1','wACLocm','','','','Loc de munca atasat','','',''
union all select 'G','','','4','Tert','AC','@tert','@dentert','150','0','1','wACTerti','','','','Tert','','Tert',''
union all select 'G','','','3','Tip gestiune','CB','@tipgestiune','','150','1','1','','M,C,A,V,P,O,I','Materiale,Cantitativa,Amanuntul,Valorica,Produse,Obiecte,Imobilizari','M','Tip gestiune','','Tip gestiune',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null