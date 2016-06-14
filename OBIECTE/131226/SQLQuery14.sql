
delete from webconfiggrid where meniu='PI' and ('RE'='' or isnull(tip,'')='RE') and ('PI'='' or isnull(subtip,'')='PI')
delete from webconfigtipuri where meniu='PI' and ('RE'='' or isnull(tip,'')='RE') and ('PI'='' or isnull(subtip,'')='PI')
delete from webconfigform where meniu='PI' and ('RE'='' or isnull(tip,'')='RE') and ('PI'='' or isnull(subtip,'')='PI')
delete from webConfigTaburi where MeniuSursa='PI' and ('RE'='' or isnull(TipSursa,'')='RE')


insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PI','RE','PI','1','Data factura','@data_factura','D','120','20','1','0',''
union all select 'PI','RE','PI','1','Data scadenta','@data_scadentei','D','120','30','1','0',''
union all select 'PI','RE','PI','1','Valuta','@denvaluta','C','80','45','1','0',''
union all select 'PI','RE','PI','1','Factura','@factura','C','150','10','1','0','if (Number(row.@factnoua)==0)    
	{ return  String(row.@facturaInit); }   
else    
	{ return String(row.@factura);}'
union all select 'PI','RE','PI','1','Nr. crt.','@nrcrt','N','70','5','1','0',''
union all select 'PI','RE','PI','1','Selectie','@selectat','CHB','100','60','1','1','if (Number(row.@suma)>0) {return 1;} else {return 0;}'
union all select 'PI','RE','PI','1','Sold','@sold','N','120','50','1','0',''
union all select 'PI','RE','PI','1','Suma','@suma','N','120','70','1','1','var t:Number=0; for (var i:int=0; i<tabel.length; i++) t+=Number(tabel[i].@suma);    
var s:number=Math.round((Number(row.@sumaFixaPoz)-(t-Number(row.@suma)))*100)/100   
if (Number(row.@suma)>Number(row.@sold) && Number(row.@factnoua) == 0)    
	{ return  Math.round((Math.min(s,Number(row.@sold))*Number(row.@selectat))*100)/100; }   
else    
	{ if (Number(row.@suma)>0 )      
		{return  Math.round((Math.min(s,Number(row.@suma))*Number(row.@selectat))*100)/100;}       
	else
		{      
'
union all select 'PI','RE','PI','1','Valoare','@valoare','N','120','40','1','0',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PI','RE','PI','21','Inc./Plati facturi','','Macheta operatie de incasari/plati facturi selectiv','','','wOPPISelectiva','','','','','1','O','wOPPISelectiva_p',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'PI','RE','PI','1','Cont','AC','@cont','@cont','120','1','0','wACConturi','','','','','','',''
union all select 'PI','RE','PI','30','Curs','N','@curs',' ','60','1','0',' ','','','','','','',''
union all select 'PI','RE','PI','2','Data','D','@data','','120','1','0','','','','','','','',''
union all select 'PI','RE','PI','50','Rest','N','@diferenta','','120','1','0','','','','','','','','Math.round((Number(row.@sumaFixa)-Number(row.@suma))*100)/100'
union all select 'PI','RE','PI','3','Numar','C','@numar','','120','1','0','','','','','','','',''
union all select 'PI','RE','PI','35','Sold tert in valuta specif.','N','@soldTert','','120','1','0','','','','','','','',''
union all select 'PI','RE','PI','40','Suma','N','@suma','','120','1','0','','','','','','','','var t:Number=0; for (var i:int=0; i<tabel.length; i++) t+=Number(tabel[i].@suma); return Math.round(t*100)/100;'
union all select 'PI','RE','PI','10','Tert','AC','@tert','@dentert','300','1','0','wACTerti','','','','','','',''
union all select 'PI','RE','PI','20','Valuta','C','@valuta',' ','60','1','0',' ','','','','','','',''