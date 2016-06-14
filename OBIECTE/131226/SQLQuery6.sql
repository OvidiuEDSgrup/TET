
if exists (select 1 from webconfigmeniu where meniu='RA') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='C' and meniu='RA'
delete from webconfigfiltre where meniu='RA' and (''='' or isnull(tip,'')='')
delete from webconfiggrid where meniu='RA' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='RA' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='RA' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='RA' and (''='' or isnull(TipSursa,'')='')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'RA','','','0','Cantitate','@cantitate','N','50','7','1','0',''
union all select 'RA','','','0','Cod','@cod','C','60','4','1','0',''
union all select 'RA','','','0','Cod intrare','@codintrare','C','100','5','1','0',''
union all select 'RA','','','0','Data','@data','D','70','3','1','0',''
union all select 'RA','','','0','Denumire','@denumire','C','150','6','1','0',''
union all select 'RA','','','0','Numar doc.','@numardoc','C','60','2','1','0',''
union all select 'RA','','','0','Tip document','@tipdocument','C','70','1','1','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'RA','RA','1','1','','Cod','Cod','@f_cod','0','',''
union all select 'RA','RA','2','1','','Denumire','Denumire','@f_denumire','0','',''
union all select 'RA','RA','3','1','','Numar doc','Numar doc','@f_numardoc','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'RA','','','1','Documente comanda','','','','wIaDocumenteComanda',' ','wStergDocumenteComanda','','','','1',' ','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'RA','RA','Avize','','D','DO','AP','yso_wIaAvizeContracte_p','17','1'
union all select 'RA','RA','Avize chitanta','','D','DO','AC','yso_wIaAvizeContracte_p','15','1'
union all select 'RA','RA','Pozitii documente','','C','RA','RA','','11','1'
union all select 'RA','RA','Transferuri','','D','DO','TE','yso_wIaTEContracte_p','13','1'
GO