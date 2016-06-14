
delete from webconfiggrid where meniu='DO' and ('AS'='' or isnull(tip,'')='AS') and ('SS'='' or isnull(subtip,'')='SS')
delete from webconfigtipuri where meniu='DO' and ('AS'='' or isnull(tip,'')='AS') and ('SS'='' or isnull(subtip,'')='SS')
delete from webconfigform where meniu='DO' and ('AS'='' or isnull(tip,'')='AS') and ('SS'='' or isnull(subtip,'')='SS')
delete from webConfigTaburi where MeniuSursa='DO' and ('AS'='' or isnull(TipSursa,'')='AS')


insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AS','SS','1','Cantitate','@cantitate','N','100','3','1','0',''
union all select 'DO','AS','SS','1','Cant. storno','@cantitate_storno','N','100','5','1','1',''
union all select 'DO','AS','SS','1','Cod','@cod','C','100','1','1','0',''
union all select 'DO','AS','SS','1','Denumire','@dencod','C','300','2','1','0',''
union all select 'DO','AS','SS','1','Pret','@pvaluta','N','100','4','1','0',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AS','SS','20','Stornare Document','','','','','wOPStornareDocument','','','','','1','O','wOPStornareDocument_p',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AS','SS','3','Data','D','@data','','100','1','0','','','','','','','',''
union all select 'DO','AS','SS','6','Data doc. storno','D','@datadoc','','100','1','1','','','','','','','',''
union all select 'DO','AS','SS','8','Data factura storno','D','@dataFactDoc','','100','1','1','','','','','','','',''
union all select 'DO','AS','SS','4','Tert','C','@dentert','','250','1','0','','','','','','','',''
union all select 'DO','AS','SS','7','Factura storno','C','@facturadoc','','100','1','1','','','','','','','',''
union all select 'DO','AS','SS','2','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'DO','AS','SS','5','Numar doc. storno','C','@numardoc','','100','1','1','','','','','','','',''
union all select 'DO','AS','SS','1','Tip','C','@tip','','50','1','0','','','','','','','',''