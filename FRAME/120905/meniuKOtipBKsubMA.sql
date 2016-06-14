delete from webconfigmeniu where tipMacheta='D' and meniu='KO'
delete from webconfigfiltre where tipMacheta='D' and meniu='KO' and ('BK'='' or isnull(tip,'')='BK')
delete from webconfiggrid where tipMacheta='D' and meniu='KO' and ('BK'='' or isnull(tip,'')='BK') and ('MA'='' or isnull(subtip,'')='MA')
delete from webconfigtipuri where tipMacheta='D' and meniu='KO' and ('BK'='' or isnull(tip,'')='BK') and ('MA'='' or isnull(subtip,'')='MA')
delete from webconfigform where tipMacheta='D' and meniu='KO' and ('BK'='' or isnull(tip,'')='BK') and ('MA'='' or isnull(subtip,'')='MA')

-------------------------------------------------------------------------------------------------------------------------------------------
--insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
--select top 0 null,null,null,null,null,null,null
--union all select '15','Contracte','1','Contracte','D','KO','3'


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigFiltre (IdUtilizator, TipMacheta, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','KO','BK','5','0','','Denumire gestiune','Denumire gestiune','@f_dengestiune','0','',''
union all select '','D','KO','BK','7','0','','Den. gest. primitoare','Den. gest.primitoare','@f_dengestprim','0','',''
union all select '','D','KO','BK','12','0','','Denumire loc munca','Denumire loc munca','@f_denlm','0','',''
union all select '','D','KO','BK','10','1','','Denumire tert','Denumire tert','@f_dentert','0','',''
union all select '','D','KO','BK','4','1','','Gest pred','Gest pred','@f_gestiune','0','',''
union all select '','D','KO','BK','6','1','','Gest prim','Gest prim','@f_gestprim','0','',''
union all select '','D','KO','BK','11','0','','Loc munca','Loc munca','@f_lm','0','',''
union all select '','D','KO','BK','2','1','','Numar','Numar','@f_numar','0','',''
union all select '','D','KO','BK','8','1','','Stare','Stare','@f_stare','0','',''
union all select '','D','KO','BK','9','0','','Tert','Tert','@f_tert','0','',''
union all select '','D','KO','BK','13','0','','Valoare jos','Valoare jos','@f_valoarejos','0','',''
union all select '','D','KO','BK','14','0','','Valoare sus','Valoare sus','@f_valoaresus','0','',''


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','KO','BK','MA','6','Modificare antet','          Operatie care permite schimbarea datelor din antet.','','','','yso_wOPModificareAntetCon','','','','','1','O','wOPModificareAntetCon_p'


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','KO','BK','MA','9','Cont client','AC','@contclient','@contclient','300','1','1','wACConturi','','','','Cont client','',''
union all select '','D','KO','BK','MA','22','Contract cadru','C','@contr_cadru','','300','1','1','','','','','Contract cadru','',''
union all select '','D','KO','BK','MA','2','Stare','C','@denstare',' ','200','1','0','','','','','','',''
union all select '','D','KO','BK','MA','15','Explicatii','C','@explicatii','','250','1','1','','','','','Explicatii','',''
union all select '','D','KO','BK','MA','10','Factura','C','@factura','','150','1','1',' ','','','','Factura','',''
union all select '','D','KO','BK','MA','5','Gestiune','AC','@gestiune','@dengestiune','200','1','1','wACGestiuni',' ',' ',' ','Gestiune','',''
union all select '','D','KO','BK','MA','7','Gest. primitoare','AC','@gestprim','@dengestprim','200','1','1','wACGestiuni','','','','Gestiune primitoare','',''
union all select '','D','KO','BK','MA','16','Info1','C','@info1','','150','1','0','','','','','Info1','',''
union all select '','D','KO','BK','MA','17','Info2','N','@info2','','150','1','0','','','','','Info2','',''
union all select '','D','KO','BK','MA','18','Info3','N','@info3','','150','1','0','','','','','Info3','',''
union all select '','D','KO','BK','MA','19','Info4','N','@info4','','150','1','0','','','','','Info4','',''
union all select '','D','KO','BK','MA','20','Info5','N','@info5','','150','1','0','','','','','Info5','',''
union all select '','D','KO','BK','MA','21','Responsabil','C','@info6','','200','1','1','','','','','Info6','',''
union all select '','D','KO','BK','MA','11','Loc munca','AC','@lm','@denlm','300','1','1','wACLocm','','','','Loc munca','',''
union all select '','D','KO','BK','MA','3','Contract','C','@n_contract','','150','1','1','','','','','Contract','',''
union all select '','D','KO','BK','MA','4','Data','D','@n_data','','100','1','1','','','','','Data','',''
union all select '','D','KO','BK','MA','6','Beneficiar','AC','@n_tert','@dentert','300','1','1','wACTerti','','','','Selectati un tert','',''
union all select '','D','KO','BK','MA','1','Tip','C','@n_tip','','50','1','0','','','','','Tip','',''
union all select '','D','KO','BK','MA','12','Proc. penalizare','N','@procpen','','60','1','1','','','','','Procent penalizare','',''
union all select '','D','KO','BK','MA','8','Punct livrare','AC','@punctlivrare','@punctlivrare','200','1','1','wACPuncteLivrare','','','','Punct livrare','',''
union all select '','D','KO','BK','MA','14','Zile scadenta','N','@scadenta','','50','1','1','','','','','Scadenta','',''
union all select '','D','KO','BK','MA','13','Valabilitate','D','@termen','','100','1','1','','','','','Valabilitate','',''
union all select '','D','KO','BK','MA','23','Valoare','N','@valoare','','100','1','1','','','','','Valoare','',''

