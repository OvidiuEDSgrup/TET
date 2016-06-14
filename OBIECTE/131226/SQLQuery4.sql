
if exists (select 1 from webconfigmeniu where meniu='ST') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='C' and meniu='ST'
delete from webconfigfiltre where meniu='ST' and (''='' or isnull(tip,'')='')
delete from webconfiggrid where meniu='ST' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='ST' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='ST' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='ST' and (''='' or isnull(TipSursa,'')='')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'ST','Stari contracte','CONTRACTE','Calcule lunare MF','C',1544.00,'','','&lt;row&gt;&lt;vechi&gt;&lt;row id="1544" nume="Stari contracte" idparinte="1050" icoana="Calcule lunare MF" tipmacheta="C" meniu="ST" modul="UC" publicabil="1"/&gt;&lt;/vechi&gt;&lt;/row&gt;',1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'ST','','','0','Culoare','@culoare','C','100','5','1','0',''
union all select 'ST','','','0','Facturabil','@denfacturabil','C','100','7','1','0',' '
union all select 'ST','','','0','Modificabil','@denmodificabil','C','100','6','1','0',''
union all select 'ST','','','0','Tip contract','@dentipcontract','G','100','1','1','0',''
union all select 'ST','','','0','Transportabil','@dentransportabil','C','100','8','1','0',' '
union all select 'ST','','','0','Denumire','@denumire','C','150','3','1','0',''
union all select 'ST','','','0','Stare','@stare','N','50','2','1','0',''
union all select 'ST','','','0','Tip contract','@tipcontract','C','100','4','0','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'ST','ST','2','1','','Denumire','Denumire','@f_denumire','0','',''
union all select 'ST','ST','3','1','','Stare','Stare','@f_stare','0','',''
union all select 'ST','ST','1','1','','Tip contract','Tip contract','@f_tipcontract','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'ST','','','1','Stari','','','','wIaStariContracte','wScriuStariContracte','wStergStariContracte','','','','1',' ','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'ST','','','4','Culoare','C','@culoare','','100','1','1','','','','','','','',''
union all select 'ST','','','3','Denumire','C','@denumire','','100','1','1','','','','','','','',''
union all select 'ST','','','6','Facturabil','CB','@facturabil','','100','1','1','','0,1','Nu,Da','0','','','',''
union all select 'ST','','','5','Modificabil','CB','@modificabil','','100','1','1','','0,1','Nu,Da','0','','','',''
union all select 'ST','','','2','Stare','N','@stare','','100','1','1','','','','','','','',''
union all select 'ST','','','1','Tip','AC','@tipcontract','@tipcontract','200','1','1','wACTipuriContracte','','','','Tip contract','','',''
union all select 'ST','','','7','Transportabil','CB','@transportabil','','100','1','1','','0,1','Nu,Da','0','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null