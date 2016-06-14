
if exists (select 1 from webconfigmeniu where meniu='PV') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='PV'
delete from webconfigfiltre where meniu='PV' and ('PV'='' or isnull(tip,'')='PV')
delete from webconfiggrid where meniu='PV' and ('PV'='' or isnull(tip,'')='PV') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='PV' and ('PV'='' or isnull(tip,'')='PV') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='PV' and ('PV'='' or isnull(tip,'')='PV') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='PV' and ('PV'='' or isnull(TipSursa,'')='PV')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PV','PV','PV','1','Date document PVria','','','','','wDateDocPV_v','','','','','1',' ','wDateDocPV_p',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PV','PV','PV','22','','','','','','0','0','','','','','','','',''
union all select 'PV','PV','PV','18','Categorie de pret','AC','@categoriePret','@dencategoriePret','250','1','1','wACCategPret','','','','Categoria de pret a documentului','','',''
union all select 'PV','PV','PV','20','Comanda livrare','AC','@comanda','@dencomanda','250','0','1',' ','','','','Comanda livrare','','',''
union all select 'PV','PV','PV','21','Comanda ASIS','AC','@comandaASIS','@dencomandaASIS','250','0','0','wACComenzi','','','','Comanda ASiS','','',''
union all select 'PV','PV','PV','14','Gestiune','AC','@GESTPV','@denGESTPV','250','0','1','wACGestiuni','','','','Gestiunea documentului','','',''
union all select 'PV','PV','PV','16','Loc de munca','AC','@lm','@denlm','250','1','1','wACLocm','','','','Loc de munca doc','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null