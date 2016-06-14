
--if exists (select 1 from webconfigmeniu where meniu='PJ') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
delete from webconfigmeniu where tipMacheta='C' and meniu='PJ'
delete from webconfigfiltre where meniu='PJ' and (''='' or isnull(tip,'')='')
delete from webconfiggrid where meniu='PJ' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='PJ' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='PJ' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='PJ' and (''='' or isnull(TipSursa,'')='')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'PJ','Configurare plaje','CONFIGURARI','tbconfig','C',10.00,'','','<row><vechi><row id="10" nume="Configurare plaje" idparinte="550" icoana="tbconfig" tipmacheta="C" meniu="PJ" modul="ED" publicabil="1"/></vechi></row>',1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PJ','','','0','Serie in numar','@denserieinnumar','C','50','9','0','0',''
union all select 'PJ','','','0','Denumire','@denumire','C','150','2','1','0',''
union all select 'PJ','','','0','Descriere','@descriere','C','100','2','1','0',' '
union all select 'PJ','','','0','Meniu','@meniupl','C','50','3','1','0',' '
union all select 'PJ','','','0','Numar inferior','@numarinferior','N','100','6','1','0',''
union all select 'PJ','','','0','Numar superior','@numarsuperior','N','100','7','1','0',''
union all select 'PJ','','','0','Serie','@serie','C','60','5','1','0',''
union all select 'PJ','','','0','Subtip','@subtippl','C','50','4','1','0',' '
union all select 'PJ','','','0','Tip document','@tipdocument','C','50','1','1','0',''
union all select 'PJ','','','0','Ultimul numar','@ultimulnumar','N','100','8','1','0',''
union all select 'PJ','AS','','0','Cod','@cod','C','100','30','1','0',''
union all select 'PJ','AS','','0','Denumire','@dentipasociere','C','100','20','1','0',''
union all select 'PJ','AS','','0','Prioritate','@prioritate','C','100','40','1','0',''
union all select 'PJ','AS','','0','Tip','@tipasociere','C','50','10','1','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'PJ','PJ','2','1','','Serie plaja','Serie','@f_serie','0','',''
union all select 'PJ','PJ','3','1','','Serie in numar','Valori: Da / Nu','@f_serieinnumar','0','',''
union all select 'PJ','PJ','1','1','','Tip document','Tip document','@f_tipdocument','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PJ','','','1','Plaje','','','','wIaPlajeDocumente','wScriuPlajeDocumente','wStergPlajeDocumente','','','','1',' ','',''
union all select 'PJ','AS','','2','Asociere plaje','Pentru asociere pe unitate, campul cod va ramane necompletat','','','wIaAsocieriPlaja','wScriuAsocieriPlaja','wStergAsocieriPlaja','','','','1',' ','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PJ','','','0','Descriere','C','@descriere','','150','1','1','','','','','','','',''
union all select 'PJ','','','1','Meniu','AC','@meniupl','@meniupl','150','1','1','wACMeniuri','','','','Meniu','','',''
union all select 'PJ',' ','','5','Numar inferior','N','@numarinferior','','100','1','1','','','','','','','',''
union all select 'PJ',' ','','6','Numar superior','N','@numarsuperior','','100','1','1','','','','','','','',''
union all select 'PJ',' ','','4','Serie','C','@serie','','100','1','1','','','','','','','',''
union all select 'PJ',' ','','8','Serie in numar','CHB','@serieinnumar','','150','0','1','','','','0','','','',''
union all select 'PJ','','','3','Subtip','AC','@subtippl','@subtippl','150','1','1','wACSubtipuri','','','','Subtip','','',''
union all select 'PJ',' ','','2','Tip document','AC','@tipdocument','@tipdocument','150','1','1','wACTipuriDocument','','','','Tip document','','',''
union all select 'PJ',' ','','7','Ultimult numar','N','@ultimulnumar','','100','1','1','','','','','','','',''
union all select 'PJ','AS','','2','Cod','AC','@cod','@cod','150','1','1','wACCodAsocierePlaja','','','','Cod','','',''
union all select 'PJ','AS','','3','Prioritate','N','@prioritate','','50','1','1','','','','','','','',''
union all select 'PJ','AS','','1','Tip','CB','@tipasociere','','150','1','1','',' ,L,G,U,J','Unitate,Loc de munca,Grup utilizatori,Utilizator,Jurnal',' ','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null