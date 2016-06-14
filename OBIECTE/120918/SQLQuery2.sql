delete from webconfigmeniu where tipMacheta='C' and meniu='PJ'
delete from webconfigfiltre where tipMacheta='C' and meniu='PJ' and (''='' or isnull(tip,'')='')
delete from webconfiggrid where tipMacheta='C' and meniu='PJ' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where tipMacheta='C' and meniu='PJ' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where tipMacheta='C' and meniu='PJ' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')

-------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
select top 0 null,null,null,null,null,null,null
union all select '0','Configurare plaje','550','tbconfig','C','PJ','ED'


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select '','C','PJ','','','0','ID plaja','@idPlaja','N','100','7','0'
union all select '','C','PJ','','','0','Ultimul numar','@ultimulnumar','N','100','6','1'
union all select '','C','PJ','','','0','Denumire','@denumire','C','150','2','1'
union all select '','C','PJ','','','0','Serie in numar','@denserieinnumar','C','50','7','1'
union all select '','C','PJ','AS','','0','Denumire','@dentipasociere','C','100','2','1'
union all select '','C','PJ','','','0','Tip document','@tipdocument','C','50','1','1'
union all select '','C','PJ','','','0','Serie','@serie','C','60','3','1'
union all select '','C','PJ','','','0','Numar inferior','@numarinferior','N','100','4','1'
union all select '','C','PJ','','','0','Numar superior','@numarsuperior','N','100','5','1'
union all select '','C','PJ','AS','','0','Tip','@tipasociere','C','50','1','1'
union all select '','C','PJ','AS','','0','Cod','@cod','C','100','3','1'
union all select '','C','PJ','AS','','0','Prioritate','@prioritate','C','100','4','1'


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigFiltre (IdUtilizator, TipMacheta, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','C','PJ','PJ','1','1','','Tip document','Tip document','@f_tipdocument','0','',''
union all select '','C','PJ','PJ','2','1','','Serie plaja','Serie','@f_serie','0','',''
union all select '','C','PJ','PJ','3','1','','Serie in numar','Valori: Da / Nu','@f_serieinnumar','0','',''


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','C','PJ','','','1','Plaje','','','','wIaPlajeDocumente','wScriuPlajeDocumente','wStergPlajeDocumente','','','','1',' ',''
union all select '','C','PJ','AS','','2','Asociere plaje','Pentru asociere pe unitate, campul cod va ramane necompletat','','','wIaAsocieriPlaja','wScriuAsocieriPlaja','wStergAsocieriPlaja','','','','1',' ',''
union all select '','C','PJ','PJ','LL','3','Listare doc. lipsa','','','','','yso_wOPListareLipsaPlajeDocumente','','','','','1','O',''


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','C','PJ',' ','','4','Numar superior','N','@numarsuperior','','100','1','1','','','','','','',''
union all select '','C','PJ',' ','','6','Serie in numar','CHB','@serieinnumar','','150','1','1','','','','0','','',''
union all select '','C','PJ','AS','','3','Prioritate','N','@prioritate','','50','1','1','','','','','','',''
union all select '','C','PJ','AS','','1','Tip','CB','@tipasociere','','150','1','0','',',L,G,U,J','Unitate,Loc de munca,Grup utilizatori,Utilizator,Jurnal',' ','Tip document','',''
union all select '','C','PJ',' ','','2','Serie','C','@serie','','100','1','1','','','','','','',''
union all select '','C','PJ',' ','','3','Numar inferior','N','@numarinferior','','100','1','1','','','','','','',''
union all select '','C','PJ',' ','','5','Ultimul numar','N','@ultimulnumar','','100','1','0','','','','','','',''
union all select '','C','PJ','AS','','2','Cod','AC','@cod','@cod','150','1','1','wACCodAsocierePlaja','','','','Cod','',''
union all select '','C','PJ',' ','','1','Tip document','AC','@tipdocument','@tipdocument','150','1','1','wACTipuriDocument','','','','Tip document','',''
union all select '','C','PJ','PJ','LL','1','Tip document','AC','@tipdocument','@tipdocument','150','1','0','wACTipuriDocument','','','','','',''
union all select '','C','PJ','PJ','LL','2','Serie','C','@serie','','100','1','0','','','','','','',''
union all select '','C','PJ','PJ','LL','3','Numar inferior','N','@numarinferior','','100','1','1','','','','','','',''
union all select '','C','PJ','PJ','LL','4','Ultimul numar','N','@ultimulnumar','','100','1','1','','','','','','',''
union all select '','C','PJ','PJ','LL','5','ID plaja','N','@idPlaja','','100','1','0','','','','','','',''

