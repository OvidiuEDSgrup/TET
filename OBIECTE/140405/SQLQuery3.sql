
--if exists (select 1 from webconfigmeniu where meniu='AD') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='AD'
delete from webconfigfiltre where meniu='AD' and ('CB'='' or isnull(tip,'')='CB')
delete from webconfiggrid where meniu='AD' and ('CB'='' or isnull(tip,'')='CB') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='AD' and ('CB'='' or isnull(tip,'')='CB') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='AD' and ('CB'='' or isnull(tip,'')='CB') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='AD' and ('CB'='' or isnull(TipSursa,'')='CB')

--insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
--				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
--select top 0 null,null,null,null,null,null,null,null,null,null
--union all select 'AD','Compensari','CONTAGEST','Compensari','D',14.00,'','','<row><vechi><row id="14" nume="Compensari" idparinte="1" icoana="Compensari" tipmacheta="D" meniu="AD" modul="1" publicabil="1"/></vechi></row>',1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'AD','CB','','1','Achit. fact.','@achitfact','N','150','21','0','0',''
union all select 'AD','CB','','1','Comanda','@comanda','C','150','27','0','0',''
union all select 'AD','CB','','1','Cont creditor','@contcred','C','150','11','1','0',''
union all select 'AD','CB','','1','Cont debitor','@contdeb','C','150','9','1','0',''
union all select 'AD','CB','','1','Cont dif.curs','@contdifcurs','C','150','22','0','0',''
union all select 'AD','CB','','1','Cota tva','@cotatva','N','50','14','0','0',''
union all select 'AD','CB','','1','Curs','@curs','N','50','17','0','0',''
union all select 'AD','CB','','0','Data','@data','D','100','3','1','0',''
union all select 'AD','CB','','1','Data','@data','D','100','3','0','0',''
union all select 'AD','CB','','1','Data facturii','@datafacturii','D','100','29','0','0',''
union all select 'AD','CB','','1','Data scadentei','@datascadentei','D','100','30','0','0',''
union all select 'AD','CB','','1','Den. comanda','@dencomanda','C','300','28','0','0',''
union all select 'AD','CB','','1','Den. cont creditor','@dencontcred','C','300','12','0','0',''
union all select 'AD','CB','','1','Den. cont debitor','@dencontdeb','C','300','10','0','0',''
union all select 'AD','CB','','1','Den. loc munca','@denlm','C','300','26','0','0',''
union all select 'AD','CB','','0','Den. tert','@dentert','C','300','5','1','0',''
union all select 'AD','CB','','1','Den. tert','@dentert','C','300','6','0','0',''
union all select 'AD','CB','','1','Dif. tva','@diftva','N','150','20','0','0',''
union all select 'AD','CB','','1','Explicatii','@explicatii','C','300','24','0','0',''
union all select 'AD','CB','','1','Factura','@facturadreapta','C','150','8','1','0',''
union all select 'AD','CB','','1','Avans','@facturastinga','C','150','7','1','0',''
union all select 'AD','CB','','1','Jurnal','@jurnal','C','50','32','0','0',''
union all select 'AD','CB','','1','Loc munca','@lm','C','150','25','0','0',''
union all select 'AD','CB','','0','Numar','@numar','C','100','2','1','0',''
union all select 'AD','CB','','1','Numar','@numar','C','150','2','0','0',''
union all select 'AD','CB','','1','Nr. pozitie','@numarpozitie','N','50','31','0','0',''
union all select 'AD','CB','','0','Nr. pozitii','@numarpozitii','N','50','9','1','0',''
union all select 'AD','CB','','0','Stare','@stare','N','50','10','0','0',''
union all select 'AD','CB','','1','Subtip','@subtip','C','50','4','0','0',''
union all select 'AD','CB','','1','Suma','@suma','N','150','13','1','0',''
union all select 'AD','CB','','1','Suma dif.curs','@sumadifcurs','N','150','23','0','0',''
union all select 'AD','CB','','1','Suma tva','@sumatva','N','150','15','0','0',''
union all select 'AD','CB','','1','Suma valuta','@sumavaluta','N','150','18','0','0',''
union all select 'AD','CB','','0','Tert','@tert','C','150','4','0','0',''
union all select 'AD','CB','','1','Tert','@tert','C','150','5','0','0',''
union all select 'AD','CB','','1','Tert benef.','@tertbenef','C','150','19','0','0',''
union all select 'AD','CB','','0','Tip','@tip','C','50','1','0','0',''
union all select 'AD','CB','','1','Tip','@tip','C','50','1','0','0',''
union all select 'AD','CB','','0','Tva','@tva22','N','150','7','1','0',''
union all select 'AD','CB','','0','Valoare','@valoare','N','200','6','1','0',''
union all select 'AD','CB','','0','Valoare valuta','@valoarevaluta','N','150','8','0','0',''
union all select 'AD','CB','','1','Valuta','@valuta','C','50','16','0','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'AD','CB','5','1','','Den. tert','Denumire tert','@f_dentert','0','',''
union all select 'AD','CB','1','1','','Numar','Numar','@f_numar','0','',''
union all select 'AD','CB','4','1','','Tert','Tert','@f_tert','0','',''
union all select 'AD','CB','6','0','','Valoare','de la','@f_valoarejos','1','pana la','@f_valoaresus'

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'AD','CB','','4','Compensari benef.','','','','wIaAdoc','','wStergAdoc','wIaPozadoc','wScriuPozadoc','wStergPozadoc','1','','',''
union all select 'AD','CB','CB','1','Compensare benef.','','','','','','',' ',' ',' ','1','','',''
union all select 'AD','CB','RN','80','Refacere inreg. cont','Operatie pentru refacere inregistrari contabile','','','','wOPRefacereInregistrariContabileDocument','','','','','1','O','wOPRefacereInregistrariContabile_p',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'AD','CB','','2','Data','D','@data','','100','1','1','','','','','Data','','',''
union all select 'AD','CB','','4','Factura','AC','@factura','@factura','300','0','1','wACFacturi','','','','Factura','','',''
union all select 'AD','CB','','1','Numar','C','@numar','','100','1','1','','','','','Numar','','',''
union all select 'AD','CB','','3','Tert','AC','@tert','@dentert','300','1','1','wACTerti','','','','Tert','','',''
union all select 'AD','CB','','5','Total','N','@valoarecutva','','100','1','0','','','','','','','',''
union all select 'AD','CB','CB','22','Achit.fact.in valuta','N','@achitfact','','80','0','1','','','','','','','',''
union all select 'AD','CB','CB','15','Comanda','C','@comanda','','80','0','1','','','','','Comanda','','',''
union all select 'AD','CB','CB','6','Cont creditor','AC','@contcred','@contcred','250','0','1','wACConturi','','','','Cont creditor','','',''
union all select 'AD','CB','CB','5','Cont debitor','C','@contdeb','@contdeb','250','0','1','wACConturi','','','','Cont debitor','','',''
union all select 'AD','CB','CB','21','Cont dif. curs','AC','@contdifcurs','','250','0','1','wACConturi','','','','Cont dif. curs','','',''
union all select 'AD','CB','CB','11','Cota tva','N','@cotatva','','40','1','1','','','','','Cota tva','','',''
union all select 'AD','CB','CB','9','Curs','N','@curs','','60','0','1','','','','','Curs','','',''
union all select 'AD','CB','CB','18','Data facturii','D','@datafacturii','','80','0','1','','','','','Data facturii','','',''
union all select 'AD','CB','CB','19','Data scadentei','D','@datascadentei','','80','0','1','','','','','Data scadentei','','',''
union all select 'AD','CB','CB','13','Explicatii','C','@explicatii','','200','0','1','','','','','Explicatii','','',''
union all select 'AD','CB','CB','4','Factura','AC','@facturadreapta','@facturadreapta','300','1','1','wACFacturiBenef','','','','Factura','','',''
union all select 'AD','CB','CB','3','Avans','AC','@facturastinga','@facturastinga','300','1','1','wACFacturiBenef','','','','Avans','','',''
union all select 'AD','CB','CB','17','Jurnal','C','@jurnal','','80','0','1','','','','','Jurnal','','',''
union all select 'AD','CB','CB','14','Loc munca','C','@lm','','80','0','1','','','','','Loc munca','','',''
union all select 'AD','CB','CB','16','Nr. pozitie','C','@numarpozitie','','60','0','1','','','','','Nr. pozitite','','',''
union all select 'AD','CB','CB','1','Tip','C','@subtip','','40','0','1','','','','','Tip','','',''
union all select 'AD','CB','CB','7','Suma','N','@suma','','80','1','1','','','','','Suma','','',''
union all select 'AD','CB','CB','20','Dif. curs in lei','N','@sumadifcurs','','80','0','1','','','','','','','',''
union all select 'AD','CB','CB','12','Suma tva','N','@sumatva','','80','1','1','','','','','Suma tva','','',''
union all select 'AD','CB','CB','10','Suma valuta','N','@sumavaluta','','80','0','1','','','','','Suma valuta','','',''
union all select 'AD','CB','CB','2','Tert beneficiar','AC','@tertbenef','@tertbenef','300','0','1','wACTerti','','','','Tert','','',''
union all select 'AD','CB','CB','8','Valuta','C','@valuta','','40','0','1','','','','','Valuta','','',''
union all select 'AD','CB','RN','3','Data','D','@data','','100','1','0','','','','','','','',''
union all select 'AD','CB','RN','2','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'AD','CB','RN','1','Tip','C','@tip','','50','1','0','','','','','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'AD','CB','Compensari benef.','','PozDoc','AD','CB','','10','1'
union all select 'AD','CB','Note contabile','','PozDoc','IK','IC','','20','1'
GO
