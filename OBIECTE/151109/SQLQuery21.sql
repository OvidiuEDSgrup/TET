
--if exists (select 1 from webconfigmeniu where meniu='RN') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
delete from webconfigmeniu where tipMacheta='D' and meniu='RN'
delete from webconfigfiltre where meniu='RN' and ('RN'='' or isnull(tip,'')='RN')
delete from webconfiggrid where meniu='RN' and ('RN'='' or isnull(tip,'')='RN') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='RN' and ('RN'='' or isnull(tip,'')='RN') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='RN' and ('RN'='' or isnull(tip,'')='RN') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='RN' and ('RN'='' or isnull(TipSursa,'')='RN')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'RN','Necesar de Aprovizionare','CONTRACTE','comenzi','D',1060.00,'','','',1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'RN','RN','','1','Cantitate','@cantitate','N','50','3','1','0',''
union all select 'RN','RN','','1','Cod','@cod','C','100','1','1','0',''
union all select 'RN','RN','','1','Cod specific','@codspecific','C','100','8','0','0',''
union all select 'RN','RN','','0','Curs','@curs','N','30','8','0','0',''
union all select 'RN','RN','','0','Data','@data','D','30','2','1','0',''
union all select 'RN','RN','','0','Denumire gestiune','@dengestiune','C','40','4','1','0',''
union all select 'RN','RN','','0','Denumire gest.prim.','@dengestiune_primitoare','C','80','9','0','0',''
union all select 'RN','RN','','0','Loc munca','@denlm','C','30','5','1','0',''
union all select 'RN','RN','','1','Periodicitate','@denperiodicitate','C','100','9','0','0',''
union all select 'RN','RN','','0','Stare','@denstare','C','20','3','1','0',''
union all select 'RN','RN','','1','Stare','@denstare','C','100','6','1','0',''
union all select 'RN','RN','','0','Denumire tert','@dentert','C','150','10','0','0',''
union all select 'RN','RN','','1','Denumire','@denumire','C','200','2','1','0',''
union all select 'RN','RN','','0','Explicatii','@explicatii','C','100','10','1','0',''
union all select 'RN','RN','','1','Explicatii','@explicatii','C','150','10','1','0',''
union all select 'RN','RN','','0','Gestiune','@gestiune','C','30','11','0','0',''
union all select 'RN','RN','','0','Gestiune primitoare','@gestiune_primitoare','C','30','12','0','0',''
union all select 'RN','RN','','0','Loc de munca','@lm','C','30','13','0','0',''
union all select 'RN','RN','','0','Numar','@numar','C','30','1','1','0',''
union all select 'RN','RN','','0','Pozitii','@pozitii','N','15','7','1','0',''
union all select 'RN','RN','','1','Pret','@pret','N','50','5','1','0',''
union all select 'RN','RN','','0','Punct livrare','@punct_livrare','C','50','14','0','0',''
union all select 'RN','RN','','0','Stare','@stare','C','50','26','0','0',''
union all select 'RN','RN','','1','Termen','@termen','D','100','7','1','1',''
union all select 'RN','RN','','0','Tert','@tert','C','50','15','0','0',''
union all select 'RN','RN','','1','UM','@um','C','30','4','1','0',''
union all select 'RN','RN','','0','Valabilitate','@valabilitate','D','80','16','0','0',''
union all select 'RN','RN','','0','Val.','@valoare','N','50','17','0','0',''
union all select 'RN','RN','','0','Val. cu TVA','@valoarecutva','N','30','6','1','0',''
union all select 'RN','RN','','0','Valuta','@valuta','C','30','18','0','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'RN','RN','10','0','','Denumire gest.','Denumire gestiune','@f_dengestiune','0','',''
union all select 'RN','RN','9','0','','Denumire loc de munca','Denumire loc munca','@f_denlm','0','',''
union all select 'RN','RN','4','1','','Gestiune','Gestiune','@f_gestiune','0','',''
union all select 'RN','RN','3','1','','Loc de munca','Cod loc munca','@f_lm','0','',''
union all select 'RN','RN','1','1','','Numar','Numar referat','@f_numar','0','',''
union all select 'RN','RN','2','1','','Stare','Stare contract','@f_stare','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'RN','RN','','1','Referate','','','','wIaContracte','','wStergContracte','wIaPozContracteSP','wScriuPozContracte','wStergPozContracte','1','','',''
union all select 'RN','RN','DR','1','Transmite necesar aprovizionare','','','','','wOPDefinitivareContractSP','','','','','1','O','',''
union all select 'RN','RN','MA','5','Modificare antet necesar','Operatia permite modificarea datelor de antet a comenzii. Atentie, aceste modificari dau efect direct si sunt jurnalizate!','','','','wOPModificareContract','','','','','1','O','',''
union all select 'RN','RN','RN','2','Pozitie referat','','','','','','','','','','1','','',''
union all select 'RN','RN','SS','4','Schimbare stare','','','','','wOPSchimbareStareContractSP','','','','','1','O','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'RN','RN','','2','Data','D','@data','','100','1','1','','','','','','','',''
union all select 'RN','RN','','8','Stare','C','@denstare','@denstare','250','1','0','','','','','','','',''
union all select 'RN','RN','','7','Responsabil','C','@detalii_responsabil','','150','0','1','','','','','Persoana','','',''
union all select 'RN','RN','','6','Explicatii','T','@explicatii','','250','1','1','','','','','','','',''
union all select 'RN','RN','','3','Gestiune','AC','@gestiune','@dengestiune','250','1','1','wACGestiuni','','','','Gestiune','','',''
union all select 'RN','RN','','4','Loc de munca','AC','@lm','@denlm','250','1','1','wACLocm','','','','Loc de munca','','',''
union all select 'RN','RN','','1','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'RN','RN','','5','Valabilitate','D','@valabilitate','','100','0','1','','','','','','','',''
union all select 'RN','RN','DR','1','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'RN','RN','MA','14','Curs','N','@curs','','50','0','1','','','','','','','',''
union all select 'RN','RN','MA','2','Data','D','@data','','200','1','1','','','','','','','',''
union all select 'RN','RN','MA','15','Responsabil','C','@detalii_responsabil','','150','0','1','','','','','Resp.','','',''
union all select 'RN','RN','MA','5','Explicatii','T','@explicatii','','300','1','1','','35','','','','','',''
union all select 'RN','RN','MA','3','Gestiune','AC','@gestiune','@dengestiune','200','1','1','wACGestiuni','','','','Gestiune','','',''
union all select 'RN','RN','MA','12','Gestiune primitoare','AC','@gestiune_primitoare','@dengestiune_primitoare','200','0','1','wACGestiuni','','','','Gestiune primitoare','','',''
union all select 'RN','RN','MA','4','Loc munca','AC','@lm','@denlm','200','1','1','wACLocm','','','','Loc munca','','',''
union all select 'RN','RN','MA','1','Necesar','C','@numar','','200','1','0','','','','','','','',''
union all select 'RN','RN','MA','11','Punct livrare','AC','@punct_livrare','@denpunct_livrare','200','0','1','wACPuncteLivrare','','','','Punct livrare','','',''
union all select 'RN','RN','MA','10','Tert','AC','@tert','@dentert','200','0','1','wACTerti','','','','Tert','','',''
union all select 'RN','RN','MA','13','Valuta','AC','@valuta','@denvaluta','200','0','1','wACValuta','','','','Valuta','','',''
union all select 'RN','RN','RN','2','Cantitate','N','@cantitate','','50','1','1','','','','','','','',''
union all select 'RN','RN','RN','1','Articol','AC','@cod','@dencod','650','1','1','wACNomenclator','','','','Articol','','',''
union all select 'RN','RN','RN','7','Cod specific','AC','@codspecific','@dencodspecific','200','0','1','wACNomSpecif','','','','Articol specific','','',''
union all select 'RN','RN','RN','5','Explicatii','C','@explicatii','','650','1','1','','','','','','','',''
union all select 'RN','RN','RN','6','Periodicitate','CB','@periodicitate','','120','0','1','','0,1,2,3,4,6,12','Fara periodicitate,Lunar,2 luni,Trimestrial,4 luni,Semestrial,Anual','0','','','',''
union all select 'RN','RN','RN','3','PretV  F tva','N','@pret','','50','1','1','','','','','','','',''
union all select 'RN','RN','RN','4','Termen','D','@termen','','100','0','1','','','','','','','',''
union all select 'RN','RN','SS','3','Explicatii','C','@explicatii_jurnal','','500','1','1','','','','','','','',''
union all select 'RN','RN','SS','1','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'RN','RN','SS','2','Stare','CB','@stare','@denstare','200','1','1','wACStariContracte','','','','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'RN','RN','Fisiere NA','','C','FF','FF','','4','1'
union all select 'RN','RN','Jurnal NA','','D','JB','JB','','2','1'
union all select 'RN','RN','Proforme','','D','PROF','PR','wPopulareProforme','30','0'
union all select 'RN','RN','Documente NA','','C','RA','RA','','3','1'
union all select 'RN','RN','Necesar Aprovizionare=NA','','PozDoc','RN','RN','','1','1'
union all select 'RN','RN','Transport','','C','TT','TT','','5','0'
GO
--Tab: Fisiere NA ---- C ,FF, FF
