
if exists (select 1 from webconfigmeniu where meniu='RN_FILIALE') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='RN_FILIALE'
delete from webconfigfiltre where meniu='RN_FILIALE' and ('RN'='' or isnull(tip,'')='RN')
delete from webconfiggrid where meniu='RN_FILIALE' and ('RN'='' or isnull(tip,'')='RN') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='RN_FILIALE' and ('RN'='' or isnull(tip,'')='RN') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='RN_FILIALE' and ('RN'='' or isnull(tip,'')='RN') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='RN_FILIALE' and ('RN'='' or isnull(TipSursa,'')='RN')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'RN_FILIALE','Necesar de aprovizionare','DOCUMENTE_FILIALE','comenzi','D',1060.00,'','',null,1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'RN_FILIALE','RN','','1','Cantitate','@cantitate','N','50','5','1','0',''
union all select 'RN_FILIALE','RN','','1','Cod','@cod','C','100','2','1','0',''
union all select 'RN_FILIALE','RN','','1','Cod specific','@codspecific','C','100','1','0','0',''
union all select 'RN_FILIALE','RN','','0','Curs','@curs','N','30','13','0','0',''
union all select 'RN_FILIALE','RN','','0','Data','@data','D','80','2','1','0',''
union all select 'RN_FILIALE','RN','','0','Denumire gestiune','@dengestiune','C','80','7','1','0',''
union all select 'RN_FILIALE','RN','','0','Denumire gest.prim.','@dengestiune_primitoare','C','80','9','0','0',''
union all select 'RN_FILIALE','RN','','0','Loc munca','@denlm','C','80','11','1','0',''
union all select 'RN_FILIALE','RN','','1','Periodicitate','@denperiodicitate','C','100','8','0','0',''
union all select 'RN_FILIALE','RN','','0','Stare','@denstare','C','50','18','1','0',''
union all select 'RN_FILIALE','RN','','0','Denumire tert','@dentert','C','150','4','0','0',''
union all select 'RN_FILIALE','RN','','1','Denumire','@denumire','C','200','3','1','0',''
union all select 'RN_FILIALE','RN','','0','Explicatii','@explicatii','C','150','100','1','0',''
union all select 'RN_FILIALE','RN','','1','Explicatii','@explicatii','C','150','9','1','0',''
union all select 'RN_FILIALE','RN','','0','Gestiune','@gestiune','C','30','6','0','0',''
union all select 'RN_FILIALE','RN','','0','Gestiune primitoare','@gestiune_primitoare','C','30','8','0','0',''
union all select 'RN_FILIALE','RN','','0','Loc de munca','@lm','C','30','10','0','0',''
union all select 'RN_FILIALE','RN','','0','Numar','@numar','C','100','1','1','0',''
union all select 'RN_FILIALE','RN','','0','Pozitii','@pozitii','N','30','19','1','0',''
union all select 'RN_FILIALE','RN','','1','Pret','@pret','N','50','7','1','0',''
union all select 'RN_FILIALE','RN','','0','Punct livrare','@punct_livrare','C','50','5','0','0',''
union all select 'RN_FILIALE','RN','','0','Stare','@stare','C','50','16','0','0',''
union all select 'RN_FILIALE','RN','','1','Termen','@termen','D','100','4','1','0',''
union all select 'RN_FILIALE','RN','','0','Tert','@tert','C','50','3','0','0',''
union all select 'RN_FILIALE','RN','','1','UM','@um','C','30','6','1','0',''
union all select 'RN_FILIALE','RN','','0','Valabilitate','@valabilitate','D','80','14','0','0',''
union all select 'RN_FILIALE','RN','','0','Val.','@valoare','N','50','15','1','0',''
union all select 'RN_FILIALE','RN','','0','Val. cu TVA','@valoarecutva','N','50','17','1','0',''
union all select 'RN_FILIALE','RN','','0','Valuta','@valuta','C','30','12','0','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'RN_FILIALE','RN','3','0','','Denumire gest.','Denumire gestiune','@f_dengestiune','0','',''
union all select 'RN_FILIALE','RN','9','0','','Denumire loc de munca','Denumire loc munca','@f_denlm','0','',''
union all select 'RN_FILIALE','RN','2','1','','Gestiune','Gestiune','@f_gestiune','0','',''
union all select 'RN_FILIALE','RN','8','1','','Loc de munca','Cod loc munca','@f_lm','0','',''
union all select 'RN_FILIALE','RN','1','1','','Numar','Numar referat','@f_numar','0','',''
union all select 'RN_FILIALE','RN','10','1','','Stare','Stare contract','@f_stare','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'RN_FILIALE','RN','','1','Necesar de aprovizionare','','','','wIaContracte','','wStergContracte','wIaPozContracte','wScriuPozContracte','wStergPozContracte','1','','',''
union all select 'RN_FILIALE','RN','DR','1','Definitivare referat','','','','','wOPDefinitivareContract','','','','','1','O','',''
union all select 'RN_FILIALE','RN','RN','2','Pozitie referat','','','','','','','','','','1','','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'RN_FILIALE','RN','','2','Data','D','@data','','100','1','1','','','','','','','',''
union all select 'RN_FILIALE','RN','','6','Responsabil','C','@detalii_responsabil','','150','0','1','','','','','Persoana','','',''
union all select 'RN_FILIALE','RN','','7','Explicatii','T','@explicatii','','250','1','1','','','','','','','',''
union all select 'RN_FILIALE','RN','','3','Gestiune','AC','@gestiune','@dengestiune','250','1','1','wACGestiuni','','','','Gestiune','','',''
union all select 'RN_FILIALE','RN','','5','Loc de munca','AC','@lm','@denlm','250','1','1','wACLocm','','','','Loc de munca','','',''
union all select 'RN_FILIALE','RN','','1','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'RN_FILIALE','RN','','4','Valabilitate','D','@valabilitate','','100','0','1','','','','','','','',''
union all select 'RN_FILIALE','RN','DR','1','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'RN_FILIALE','RN','RN','3','Cantitate','N','@cantitate','','50','1','1','','','','','','','',''
union all select 'RN_FILIALE','RN','RN','1','Cod','AC','@cod','@dencod','350','1','1','wACNomenclator','','','','Articol','','',''
union all select 'RN_FILIALE','RN','RN','2','Cod specific','AC','@codspecific','@dencodspecific','200','0','1','wACNomSpecif','','','','Articol specific','','',''
union all select 'RN_FILIALE','RN','RN','7','Explicatii','C','@explicatii','','200','1','1','','','','','','','',''
union all select 'RN_FILIALE','RN','RN','6','Periodicitate','CB','@periodicitate','','120','0','1','','0,1,2,3,4,6,12','Fara periodicitate,Lunar,2 luni,Trimestrial,4 luni,Semestrial,Anual','0','','','',''
union all select 'RN_FILIALE','RN','RN','4','Pret','N','@pret','','50','1','1','','','','','','','',''
union all select 'RN_FILIALE','RN','RN','5','Termen','D','@termen','','100','1','1','','','','','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'RN_FILIALE','RN','Jurnal referat','','D','JB','JB','','2','1'
union all select 'RN_FILIALE','RN','Proforme','','D','PROF','PR','wPopulareProforme','30','0'
union all select 'RN_FILIALE','RN','Referat','','PozDoc','RN_FILIALE','RN','','1','1'
GO
--Tab: Jurnal referat ---- D ,JB, JB

if exists (select 1 from webconfigmeniu where meniu='JB') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='JB'
delete from webconfigfiltre where meniu='JB' and ('JB'='' or isnull(tip,'')='JB')
delete from webconfiggrid where meniu='JB' and ('JB'='' or isnull(tip,'')='JB') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='JB' and ('JB'='' or isnull(tip,'')='JB') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='JB' and ('JB'='' or isnull(tip,'')='JB') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='JB' and ('JB'='' or isnull(TipSursa,'')='JB')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'JB','Jurnal-tab','CONTRACTE',' ','D',1540.00,' ',' ',null,0

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','','0','Data','@data','C','100','1','1','0',''
union all select 'JB','JB','','0','Denumire stare','@denstare','C','100','3','1','0',''
union all select 'JB','JB','','0','Explicatii','@explicatii','C','150','5','1','0',''
union all select 'JB','JB','','0','Stare','@stare','C','50','2','1','0',''
union all select 'JB','JB','','0','Utilizator','@utilizator','C','100','4','1','0',''
union all select 'JB','JB','VA','1','Cantitate','@cantitate','N','100','5','1','0',' '
union all select 'JB','JB','VA','1','Cod','@cod','C','150','1','1','0',' '
union all select 'JB','JB','VA','1','Denumire','@dencod','C','300','2','1','0',' '
union all select 'JB','JB','VA','1','Discount','@discount','N','80','4','1','0',' '
union all select 'JB','JB','VA','1','Pret','@pret','N','100','3','1','0',' '
union all select 'JB','JB','VA','1','Termen','@termen','D','100','6','1','0',' '

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','2','1','','Denumire stare','Denumire stare','@f_denstare','0','',''
union all select 'JB','JB','1','1','','Stare','Stare','@f_stare','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','','1','Jurnal contract','','','','wIaJurnalContract','','','','','','1',' ','',''
union all select 'JB','JB','EX','10','Export jurnal','','','','','WexportExcel','','','','','1','O','exportJurnalContracteDemoExcel_p',''
union all select 'JB','JB','AA','1','Vizualizare act aditional','','','','','','','','','','0','O','wOPVizualizareActAditionalContract_p',''
union all select 'JB','JB','VA','1','Vizualizare act aditional','','','',' ','','','','','','1','O','wOPVizualizareActAditionalContract_p',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','EX','10','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'JB','JB','VA','2','Data','D','@data','','150','1','0','','','','','','','',''
union all select 'JB','JB','VA','1','Numar','C','@numar','','150','1','0','','','','','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null 
GO
--Tab: Proforme ---- D ,PROF, PR

if exists (select 1 from webconfigmeniu where meniu='PROF') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='PROF'
delete from webconfigfiltre where meniu='PROF' and ('PR'='' or isnull(tip,'')='PR')
delete from webconfiggrid where meniu='PROF' and ('PR'='' or isnull(tip,'')='PR') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='PROF' and ('PR'='' or isnull(tip,'')='PR') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='PROF' and ('PR'='' or isnull(tip,'')='PR') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='PROF' and ('PR'='' or isnull(TipSursa,'')='PR')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'PROF','TAB Proforme','CL','','D',100.00,'','',null,1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PROF','PR','','1','Cantitate','@cantitate','N','50','9','1','0',''
union all select 'PROF','PR','','1','Cod','@cod','C','100','3','1','0',''
union all select 'PROF','PR',' ','1','Cod specific','@codspecific','C','100','1','0','0',''
union all select 'PROF','PR','','1','Cota tva','@cotatva','N','50','15','1','0',''
union all select 'PROF','PR','','0','Curs','@curs','N','30','25','0','0',''
union all select 'PROF','PR',' ','0','Data','@data','D','80','4','1','0',''
union all select 'PROF','PR','','0','Denumire gestiune','@dengestiune','C','80','13','1','0',''
union all select 'PROF','PR','','0','Denumire gest.prim.','@dengestiune_primitoare','C','80','17','0','0',''
union all select 'PROF','PR','','0','Loc munca','@denlm','C','60','20','1','0',' '
union all select 'PROF','PR','','1','Periodicitate','@denperiodicitate','C','100','21','0','0',''
union all select 'PROF','PR','','0','Stare','@denstare','C','50','30','1','0',''
union all select 'PROF','PR','','0','Denumire tert','@dentert','C','150','7','1','0',''
union all select 'PROF','PR','','1','Denumire','@denumire','C','200','5','1','0',''
union all select 'PROF','PR','','1','Discount','@discount','N','50','18','1','0',''
union all select 'PROF','PR','','1','Explicatii','@explicatii','C','150','23','0','0',''
union all select 'PROF','PR','','0','Gestiune','@gestiune','C','30','11','0','0',''
union all select 'PROF','PR','','0','Gestiune primitoare','@gestiune_primitoare','C','30','16','0','0',''
union all select 'PROF','PR','','0','Loc de munca','@lm','C','30','19','0','0',''
union all select 'PROF','PR','','0','Numar','@numar','C','100','2','1','0',''
union all select 'PROF','PR','','0','Pozitii','@pozitii','N','30','31','1','0',''
union all select 'PROF','PR','','1','Pret','@pret','N','50','14','1','0',''
union all select 'PROF','PR','','0','Punct livrare','@punct_livrare','C','50','10','0','0',''
union all select 'PROF','PR','','0','Stare','@stare','C','50','28','0','0',''
union all select 'PROF','PR','','1','Termen','@termen','D','100','8','0','0',''
union all select 'PROF','PR','','0','Tert','@tert','C','50','6','0','0',''
union all select 'PROF','PR','','1','UM','@um','C','30','12','1','0',''
union all select 'PROF','PR','','0','Valabilitate','@valabilitate','D','80','26','0','0',''
union all select 'PROF','PR','','0','Val.','@valoare','N','50','27','1','0',''
union all select 'PROF','PR','','0','Val. cu TVA','@valoarecutva','N','50','29','1','0',' '
union all select 'PROF','PR','','0','Valuta','@valuta','C','30','24','0','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'PROF','PR','1','1','','Numar','Numar doc.','@f_numar','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PROF','PR','','1','Proforme','','','','wIaContracte','','wStergContracte','wIaPozContracte','wScriuPozContracte','wStergPozContracte','1','M','',''
union all select 'PROF','PR','PR','2','Pozitie Proforma','','','','','','','','','','1','','',''
union all select 'PROF','PR','SS','10','Schimbare stare','','','','','wOPSchimbareStareContract','','','','','1','O','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PROF','PR','','10','Curs','N','@curs','','50','1','1','','','','','','','',''
union all select 'PROF','PR','','2','Data','D','@data',' ','100','1','1','','','','','','','',''
union all select 'PROF','PR','','11','Responsabil','C','@detalii_responsabil','','150','0','1','','','','','Persoana','','',''
union all select 'PROF','PR','','13','Explicatii','T','@explicatii','','250','1','1','','','','','','','',''
union all select 'PROF','PR','','3','Gestiune','AC','@gestiune','@dengestiune','250','1','1','wACGestiuni','','','','Gestiune','','',''
union all select 'PROF','PR','','4','Gestiune primitoare','AC','@gestiune_primitoare','@dengestiune_primitoare','250','0','1','wACGestiuni','','','','Gestiune primitoare','','',''
union all select 'PROF','PR','','12','Contract','AC','@idContractCorespondent','@denidContractCorespondent','250','1','1','wACContracteBeneficiar','','','','Contractul corespondent...','','',''
union all select 'PROF','PR','','8','Loc de munca','AC','@lm','@denlm','250','1','1','wACLocm','','','','Loc de munca','','',''
union all select 'PROF','PR','','1','Numar','C','@numar',' ','100','1','0','','','','','','','',''
union all select 'PROF','PR','','6','Punct livrare','AC','@punct_livrare','@denpunct_livrare','250','1','1','wACPuncteLivrare','','','','Punct livrare','','',''
union all select 'PROF','PR','','5','Tert','ACA','@tert','@dentert','250','1','1','wACTerti','','','','Tert','','',''
union all select 'PROF','PR','','7','Valabilitate','D','@valabilitate',' ','100','0','1','','','','','','','',''
union all select 'PROF','PR','','9','Valuta','AC','@valuta','@denvaluta','200','1','1','wACValuta','','','','Valuta','','',''
union all select 'PROF','PR','PR','3','Cantitate','N','@cantitate',' ','50','1','1','','','','','','','',''
union all select 'PROF','PR','PR','1','Cod','AC','@cod','@dencod','350','1','1','wACNomenclator','','','','Articol','','',''
union all select 'PROF','PR','PR','2','Cod specific','AC','@codspecific','@dencodspecific','200','0','1','wACNomSpecif','','','','Articol specific','','',''
union all select 'PROF','PR','PR','9','Gest. pozitie','AC','@detalii_gestiune','@detalii_dengestiune','250','0','1','wacgestiuni','','','','','','',''
union all select 'PROF','PR','PR','5','Discount','N','@discount',' ','50','0','1','','','','','','','',''
union all select 'PROF','PR','PR','8','Explicatii','C','@explicatii','','200','0','1','','','','','','','',''
union all select 'PROF','PR','PR','10','Poz. contract','AC','@idPozContractCoresp','','250','0','1','wACPozitiiContractCorespondent','','','','Poz. contract corespondent','','',''
union all select 'PROF','PR','PR','7','Periodicitate','CB','@periodicitate','','120','0','1','','0,1,2,3,4,6,12','Fara periodicitate,Lunar,2 luni,Trimestrial,4 luni,Semestrial,Anual','0','','','',''
union all select 'PROF','PR','PR','4','Pret','N','@pret',' ','50','1','1','','','','','','','',''
union all select 'PROF','PR','PR','6','Termen','D','@termen',' ','100','0','1','','','','','','','',''
union all select 'PROF','PR','SS','3','Explicatii','C','@explicatii_jurnal','','300','1','1','','','','','','','',''
union all select 'PROF','PR','SS','1','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'PROF','PR','SS','2','Stare','AC','@stare','@denstare','150','1','1','wACStariContracte','','','','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'PROF','PR','Jurnal comanda','','D','JB','JB','','2','1'
union all select 'PROF','PR','Proforma','','PozDoc','PROF','PR','wPopulareProforme','1','1'
GO
--Tab: Jurnal comanda ---- D ,JB, JB

if exists (select 1 from webconfigmeniu where meniu='JB') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='JB'
delete from webconfigfiltre where meniu='JB' and ('JB'='' or isnull(tip,'')='JB')
delete from webconfiggrid where meniu='JB' and ('JB'='' or isnull(tip,'')='JB') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='JB' and ('JB'='' or isnull(tip,'')='JB') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='JB' and ('JB'='' or isnull(tip,'')='JB') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='JB' and ('JB'='' or isnull(TipSursa,'')='JB')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'JB','Jurnal-tab','CONTRACTE',' ','D',1540.00,' ',' ',null,0

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','','0','Data','@data','C','100','1','1','0',''
union all select 'JB','JB','','0','Denumire stare','@denstare','C','100','3','1','0',''
union all select 'JB','JB','','0','Explicatii','@explicatii','C','150','5','1','0',''
union all select 'JB','JB','','0','Stare','@stare','C','50','2','1','0',''
union all select 'JB','JB','','0','Utilizator','@utilizator','C','100','4','1','0',''
union all select 'JB','JB','VA','1','Cantitate','@cantitate','N','100','5','1','0',' '
union all select 'JB','JB','VA','1','Cod','@cod','C','150','1','1','0',' '
union all select 'JB','JB','VA','1','Denumire','@dencod','C','300','2','1','0',' '
union all select 'JB','JB','VA','1','Discount','@discount','N','80','4','1','0',' '
union all select 'JB','JB','VA','1','Pret','@pret','N','100','3','1','0',' '
union all select 'JB','JB','VA','1','Termen','@termen','D','100','6','1','0',' '

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','2','1','','Denumire stare','Denumire stare','@f_denstare','0','',''
union all select 'JB','JB','1','1','','Stare','Stare','@f_stare','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','','1','Jurnal contract','','','','wIaJurnalContract','','','','','','1',' ','',''
union all select 'JB','JB','EX','10','Export jurnal','','','','','WexportExcel','','','','','1','O','exportJurnalContracteDemoExcel_p',''
union all select 'JB','JB','AA','1','Vizualizare act aditional','','','','','','','','','','0','O','wOPVizualizareActAditionalContract_p',''
union all select 'JB','JB','VA','1','Vizualizare act aditional','','','',' ','','','','','','1','O','wOPVizualizareActAditionalContract_p',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','EX','10','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'JB','JB','VA','2','Data','D','@data','','150','1','0','','','','','','','',''
union all select 'JB','JB','VA','1','Numar','C','@numar','','150','1','0','','','','','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null  