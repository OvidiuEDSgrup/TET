
--if exists (select 1 from webconfigmeniu where tipMacheta='D' and meniu='BO') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='BO'
delete from webconfigfiltre where tipMacheta='D' and meniu='BO' and ('BN'='' or isnull(tip,'')='BN')
delete from webconfiggrid where tipMacheta='D' and meniu='BO' and ('BN'='' or isnull(tip,'')='BN') and (''='' or isnull(subtip,'')='')
--delete from webconfigtipuri where tipMacheta='D' and meniu='BO' and ('BN'='' or isnull(tip,'')='BN') and (''='' or isnull(subtip,'')='')
delete from webconfigform where tipMacheta='D' and meniu='BO' and ('BN'='' or isnull(tip,'')='BN') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='BO' and ('BN'='' or isnull(TipSursa,'')='BN')

--insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
--select top 0 null,null,null,null,null,null,null
--union all select '31','Bonuri','9','Bonuri','D','BO','0'

insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','BO','BN','','1','Cantitate','@cantitate','N','80','3','1','0',''
union all select '','D','BO','BN','','0','Casa de marcat','@casam','N','100','7','1','0',''
union all select '','D','BO','BN','','1','Cod','@cod','C','100','1','1','0',''
union all select '','D','BO','BN','','0','Data','@data','D','80','2','1','0',''
union all select '','D','BO','BN','','0','Denumire gestiune','@dengestiune','C','200','6','1','0',''
union all select '','D','BO','BN','','0','Beneficiar','@dentert','C','250','9','1','0',''
union all select '','D','BO','BN','','1','Denumire','@denumire','C','250','2','1','0',''
union all select '','D','BO','BN','','0','Factura','@factura','C','100','10','1','0',''
union all select '','D','BO','BN','','0','Gestiune','@gestiune','C','80','5','1','0',''
union all select '','D','BO','BN','','0','Numar bon','@numar','C','100','1','1','0',''
union all select '','D','BO','BN','','0','Numar pozitii','@numarpozitii','N','100','4','1','0',''
union all select '','D','BO','BN','','0','Ora','@ora','D','50','2','1','0',''
union all select '','D','BO','BN','','1','Pret cu TVA','@pret','N','80','4','1','0',''
union all select '','D','BO','BN','','1','TVA','@tva','N','80','5','1','0',''
union all select '','D','BO','BN','','0','Valoare','@valtotala','N','120','3','1','0',''
union all select '','D','BO','BN','','0','Vanzator','@vanzator','C','150','8','1','0',''

insert into webconfigFiltre (IdUtilizator, TipMacheta, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','BO','BN','2','0','','Data','Data bon','@data','0','',''
union all select '','D','BO','BN','3','1','','Casa','Casa de marcat','@f_casam','0','',''
union all select '','D','BO','BN','4','0','','Benenficiar','Tert','@f_dentert','0','',''
union all select '','D','BO','BN','5','0','','Factura','Numar factura','@f_factura','0','',''
union all select '','D','BO','BN','6','1','','Gestiunea','Cod gestiune','@f_gestiune','0','',''
union all select '','D','BO','BN','1','1','','Numar','Numar bon','@numar','0','',''

--insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
--select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
--union all select '','D','BO','BN','','1','Bon casa','','','','wIaBonuri','','','wIaPozBonuri',' ','','1','','',''
--union all select '','D','BO','BN','AF','1','Anulare bon','Operatie de anulare bon! Operatia va anula bonul fie ca are factura, fie ca nu are.  In ambele cazuri operatia va sterge documente corespunzatoare CG: AC/TE.','','','','wOPAnulareBon','','','','','1','','',''
--union all select '','D','BO','BN','BN','1','Pozitie bon','','','','','','','','','','1','','',''
--union all select '','D','BO','BN','DB','3','Dealocare bon','Operatie de stergere date de factura de pe bonul selectat fara a sterge bonul!','','','','wOPDealocareBon','','','','','1','O','wOPDealocareBon_p',''
--union all select '','D','BO','BN','RF','2','Refacere AC/TE','Refacere AC/AP si TE din bonuri (bp) pe bonul si gestiunea bonului selectat. Se presupune ca gestiunea data apare si pe AP si pe AC, iar TE automat se face in ambele cazuri.','','','','wOPRefacACTE','','','','','1','O','',''
--union all select '','D','BO','BN','SB','4','Stornare bon','Operatia realizeaza stornarea bonului selectat generand o factura storno,o plata diverse, si listeaza formularul de factura si plata.','','','','wOPStornareBon','','','','','1','O','wOPStornareBon_p',''

insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','D','BO','BN','','3','Casa','N','@casam','','40','1','1','','','','','Nr. casa','','',''
union all select '','D','BO','BN',' ','2','Data','D','@data','','80','1','1','','','','','','','',''
union all select '','D','BO','BN','','5','Beneficiar','C','@dentert','','250','1','1','','','','','Nume beneficiar','','',''
union all select '','D','BO','BN','','1','Numar bon','C','@numar','','80','1','1','','','','','','','',''
union all select '','D','BO','BN','','6','Valoare','N','@valtotala','','100','1','1','','','','','Valoare cu TVA','','',''
union all select '','D','BO','BN','','4','Vanzator','C','@vanzator','','150','1','1','','','','','Nume vanzator','','',''
union all select '','D','BO','BN','AF','6','Anulare bon/factura','CHB','@anularefact','','200','1','1','','','','','Anulare bon/factura','','',''
union all select '','D','BO','BN','AF','2','Data','D','@data','','100','1','0','','','','','','','',''
union all select '','D','BO','BN','AF','5','Beneficiar','C','@dentert','','250','1','0','','','','','','','',''
union all select '','D','BO','BN','AF','1','Numar bon','C','@numar','','100','1','0','','','','','','','',''
union all select '','D','BO','BN','AF','3','Valoare','N','@valtotala','','80','1','0','','','','','','','',''
union all select '','D','BO','BN','AF','4','Vanzator','C','@vanzator','','150','1','0','','','','','','','',''
union all select '','D','BO','BN','DB','1','Bon nr:','C','@bon','','100','1','0','','','','','','','',''
union all select '','D','BO','BN','DB','3','Client','C','@client','','250','1','0','','','','','','','',''
union all select '','D','BO','BN','DB','2','Data bon','D','@databon','','100','1','0','','','','','','','',''
union all select '','D','BO','BN','DB','5','Data facturii','D','@datafacturii','','100','1','0','','','','','','','',''
union all select '','D','BO','BN','DB','4','Factura','C','@factura','','100','1','0','','','','','','','',''
union all select '','D','BO','BN','RF','2','Generare documente','CHB','@generare','','200','1','1','','','','','','','',''
union all select '','D','BO','BN','RF','1','Stergere documente','CHB','@stergere','','200','1','1','','','','','','','',''
union all select '','D','BO','BN','SB','4','Data','D','@data_storno','','200','1','0','','','','','','','',''
union all select '','D','BO','BN','SB','2','Gestiune','AC','@gestiune_storno','@dengestiune_storno','200','1','0','wACGestiuni','','','','','','',''
union all select '','D','BO','BN','SB','3','Loc de munca','AC','@lm_storno','@denlm_storno','200','1','0','wACLocm','','','','','','',''
union all select '','D','BO','BN','SB','1','Tert','AC','@tert_storno','','200','1','1','wACTerti','','','','Tert factura','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null