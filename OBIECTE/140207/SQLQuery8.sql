
delete from webconfiggrid where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('DF'='' or isnull(subtip,'')='DF')
delete from webconfigtipuri where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('DF'='' or isnull(subtip,'')='DF')
delete from webconfigform where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('DF'='' or isnull(subtip,'')='DF')
delete from webConfigTaburi where MeniuSursa='DO' and ('AP'='' or isnull(TipSursa,'')='AP')


insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','BK','GT','3','Detalii Transport','','','','','wOPScriuDetaliiFacturare','','','','','1','O','wOPScriuDetaliiFacturare_p',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','BK','GT','17','Data expedierii','D','@data_expedierii',' ','100','1','1','','','','','','','',''
--union all select 'CO','BK','GT','14','Eliberat','C','@eliberat','','300','0','1','','','','','','','',''
union all select 'CO','BK','GT','20','Explicatii doc.','C','@explicatii_anexad','','300','1','1','','','','','','','',''
union all select 'CO','BK','GT','19','Explicatii fact.','C','@explicatii_anexaf','','300','1','1','','','','','','','',''
--union all select 'CO','BK','GT','15','Mijloc de transport','C','@mijloc_de_transport','','200','1','1','','','','','','','',''
--union all select 'CO','BK','GT','13','Numar buletin','C','@numar_buletin','','150','0','1','','','','','','','',''
--union all select 'CO','BK','GT','16','Numarul mijlocului de transport','C','@numarul_mijlocului','','150','0','1','','','','','','','',''
--union all select 'CO','BK','GT','11','Nume delegat','C','@numele_delegatului','','300','1','1','','','','','Optional, se completeaza numele delegatului,','','',''
union all select 'CO','BK','GT','18','Ora expedierii','C','@ora_expedierii','','100','1','1','','','','','','','',''
--union all select 'CO','BK','GT','12','Serie buletin','C','@seria_buletin','','100','1','1','','','','','','','',''