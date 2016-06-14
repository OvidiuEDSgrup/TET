
delete from webconfiggrid where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('GF'='' or isnull(subtip,'')='GF')
delete from webconfigtipuri where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('GF'='' or isnull(subtip,'')='GF')
delete from webconfigform where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('GF'='' or isnull(subtip,'')='GF')
delete from webConfigTaburi where MeniuSursa='CO' and ('BK'='' or isnull(TipSursa,'')='BK')


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
union all select 'CO','BK','GF','3','Generare factura','           Operatie pentru generarea facturilor pe baza comenzilor de livrare. Se pot factura doar pozitiile care au cantitate disponibila, si numai in limita stocului existent. Exista posibilitatea de a se generara mai multe facturi de pe aceasi comanda de livrare fara insa a se depasi cantitatile disponibile.','','','','wOPGenerareUnAPdinBK','','','','','1','O','wOPGenerareUnAPdinBK_p',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','BK','GF','3','Data factura','D','@datadoc','','100','1','1','','','','','Data transfer','','',''
union all select 'CO','BK','GF','1','Beneficiar','C','@dentert','','350','1','0','','','','','Tert','','',''
union all select 'CO','BK','GF','9','Eliberat','C','@eliberat','','150','1','1','','','','','','','',''
union all select 'CO','BK','GF','5','Mijloc de transport','C','@mijloctp','','150','1','1','','','','','Mijloc de transport','','',''
union all select 'CO','BK','GF','6','Numar mijl transport','C','@nrmijltransp','','100','1','1','','','','','Nr mijloc de transport','','',''
union all select 'CO','BK','GF','8','Numar Buletin','C','@numarbuletin','','100','1','1','','','','','','','',''
union all select 'CO','BK','GF','2','Factura','C','@numardoc','','100','1','1','','','','','Numar transfer','','',''
union all select 'CO','BK','GF','4','Nume delegat','C','@numedelegat','','150','1','1','','','','','Nume delegat','','',''
union all select 'CO','BK','GF','10','Observatii','C','@observatii','','300','1','1','','','','','Observatii','','',''
union all select 'CO','BK','GF','7','Serie Buletin','C','@seriabuletin','','150','1','1','','','','','','','',''