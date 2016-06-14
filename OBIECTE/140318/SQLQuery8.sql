
delete from webconfiggrid where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('GF'='' or isnull(subtip,'')='GF')
delete from webconfigtipuri where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('GF'='' or isnull(subtip,'')='GF')
delete from webconfigform where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('GF'='' or isnull(subtip,'')='GF')
--delete from webConfigTaburi where MeniuSursa='CO' and ('BK'='' or isnull(TipSursa,'')='BK')


insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','BK','GF','1','Cant.aprobata','@cant_aprobata','N','150','3','1','0',''
union all select 'CO','BK','GF','1','Cant.realizata','@cant_realizata','N','150','4','1','0',''
union all select 'CO','BK','GF','1','Cant.disponibila','@cantitate_disponibila','N','150','5','1','0',''
union all select 'CO','BK','GF','1','Cant.de facturat','@cantitate_factura','N','150','6','1','1',''
union all select 'CO','BK','GF','1','Cod','@cod','C','100','1','1','0',''
union all select 'CO','BK','GF','1','Denumire','@denumire','C','300','2','1','0',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','BK','GF','3','Generare factura','            Operatie pentru generarea facturilor pe baza comenzilor de livrare. Se pot factura doar pozitiile care au cantitate disponibila, si numai in limita stocului existent. Exista posibilitatea de a se generara mai multe facturi de pe aceasi comanda de livrare fara insa a se depasi cantitatile disponibile.','','','','wOPGenerareUnAPdinBK','','','','','1','O','wOPGenerareUnAPdinBK_p',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','BK','GF','35','Aviz nefacturat','CHB','@aviznefacturat','','100','1','1','','','','','','','',''
union all select 'CO','BK','GF','110','Data expedierii','D','@data_expedierii','','100','0','1','','','','','','','',''
union all select 'CO','BK','GF','30','Data factura','D','@datadoc','','100','1','1','','','','','Data transfer','','',''
union all select 'CO','BK','GF','10','Beneficiar','C','@dentert','','300','1','0','','','','','Tert','','',''
union all select 'CO','BK','GF','90','Eliberat','C','@eliberatbuletin','','150','1','1','','','','','','','','if (Number(row.@noudelegat)==1) {return row.@eliberatbuletin;} else {return String(row.@numedelegat).substr(112,30).replace(/^\s+|\s+$/g, "");}'
union all select 'CO','BK','GF','40','Nume delegat','AC','@iddelegat','@numedelegat','150','1','1','wACPersoaneContactSP','','','','Completati delegatul','','',''
union all select 'CO','BK','GF','99','Tip mijloc de transport','C','@mijloctp',' ','100','0','1','','','','','','','','if (Number(row.@noumijltp)==1) {return row.@mijloctp;} else {return String(row.@denmijloctp).substr(10,30).replace(/^\s+|\s+$/g, "");}'
union all select 'CO','BK','GF','100','Mod plata','CB','@modPlata','','150','1','1','','CEC,OP,CARD,NUMERAR,COMPENSARE','CEC,OP,CARD,NUMERAR,COMPENSARE','','','','',''
union all select 'CO','BK','GF','43','Adaug/Modific','CHB','@noudelegat','','100','1','1','','','','','','','',''
union all select 'CO','BK','GF','97','Adaug/Modific','CHB','@noumijltp','@denmijloctp','100','0','1','','','','','','','',''
union all select 'CO','BK','GF','130','Formular','CB','@nrformular','@denformular','300','1','1','wACFormulare','','','','Alegeti formularul','','',''
union all select 'CO','BK','GF','95','Nr mijloc de transport','AC','@nrmijltransp','@nrmijltransp','150','1','1','yso_wACMasinExp','','','','Completati mijlocul de transport','','',''
union all select 'CO','BK','GF','80','Numar Buletin','C','@numarbuletin','','100','1','1','','','','','','','','if (Number(row.@noudelegat)==1) {return row.@numarbuletin;} else {return String(row.@numedelegat).substr(103,9).replace(/^\s+|\s+$/g, "");}'
union all select 'CO','BK','GF','20','Factura','C','@numardoc','','100','1','1','','','','','Numar transfer','','',''
union all select 'CO','BK','GF','100','Observatii','C','@observatii','','300','0','1','','80','','','Observatii','','',''
union all select 'CO','BK','GF','120','Ora expedierii','C','@ora_expedierii','','75','0','1','','','','','','','',''
union all select 'CO','BK','GF','45','Prenume delegat','C','@prenumedelegat','','150','1','1','','','','','','','','if (Number(row.@noudelegat)==1) {return row.@prenumedelegat;} else {return String(row.@numedelegat).substr(70,30).replace(/^\s+|\s+$/g, "");}'
union all select 'CO','BK','GF','70','Serie Buletin','C','@seriebuletin','','100','1','1','','','','','','','','if (Number(row.@noudelegat)==1) {return row.@seriebuletin;} else {return String(row.@numedelegat).substr(100,3).replace(/^\s+|\s+$/g, "");}'