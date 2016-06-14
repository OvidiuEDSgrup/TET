/*
if exists (select 1 from webconfigmeniu where tipMacheta='O' and meniu='GT') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--*/delete from webconfigmeniu where tipMacheta='O' and meniu='GT'
delete from webconfiggrid where tipMacheta='O' and meniu='GT' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where tipMacheta='O' and meniu='GT' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where tipMacheta='O' and meniu='GT' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
select top 0 null,null,null,null,null,null,null
union all select '300460','Golire gest.prin transf.storno','3','Preluare','O','GT',''

insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, Ordine, NumeCol, DataField, TipObiect, Latime, Vizibil, modificabil) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','O','GT','','','0','1','Cod articol','@cod','C','100','1','0'
union all select '','O','GT','','','0','2','Den.articol','@dencod','C','300','1','0'
union all select '','O','GT','','','0','3','Gest.','@gestsursa','C','70','1','0'
union all select '','O','GT','','','0','4','Den.gestiune sursa','@dengestsursa','C','200','1','0'
union all select '','O','GT','','','0','5','Cant.transferata','@cant_transferata','N','125','1','0'
union all select '','O','GT','','','0','6','Cant.disponibila','@cant_disponibila','N','125','1','0'
union all select '','O','GT','','','0','7','Pret amanunt','@pamanunt','N','125','1','0'
union all select '','O','GT','','','0','8','Cant.storno','@cant_storno','N','100','1','1'

insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','O','GT','','','1','Preluare receptie','Operatie de generare TE storno pt golirea unei gestiuni.','','','','yso_wOPGolireGestPrinTEStorno','','','','','1',' ','yso_wOPGolireGestPrinTEStorno_p'

insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','O','GT','','','1','Gestiunea care se goleste','AC','@gestprim','@dengestprim','300','1','0','wACGestiuni','','','','Selectati gestiunea primitoare','',''
union all select '','O','GT','','','2','Gestiunea in care se transfera','CB','@gestiune','@dengestiune','300','1','1','wACGestiuni','','','',' ','',''
union all select '','O','GT','','','3','Numar transfer storno','C','@numar','','100','1','1','','','','','Numar doc.','','Daca nu-l introduceti se va da urmatorul din plaja.'
union all select '','O','GT','','','4','Data transfer storno','D','@data','','100','1','1','','','','','','',''
