-- acest script trebuie rulat o singura data, la instalarea aplicatiei.
-- atentie: daca exista doar o parte din aceste linii, faceti insert manual pentru a fi inserate toate 
-- (sau stergeti tot cu tipMacheta='L' sau 'M'

insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','M','MD','','','3','Text','C','@text','','300','0','0','','','','','','',''
union all select ' ','M','CN','','','1','Nume','C','@nume','','300','1','1','','','','','','',''
union all select '','M','CN','','','2','Functie','C','@functie','','300','1','1','','','','','','',''
union all select '','M','CN','','','3','ID Messenger','C','@yahoomess','','300','1','1','','','','','','',''
union all select '','M','CN','','','4','Numar telefon','C','@telefon','','300','1','1','','','','','','',''
union all select '','M','CH','','','15','Seria','C','@serie','','300','1','1','','','','','','',''
union all select '','M','CH','','','17','Numar','N','@numar','','300','1','1','','','','','','',''
union all select '','M','CH','','','13','Suma','N','@suma','','300','1','1','','','','','','',''
union all select '','M','CH','','','14','Data','D','@data','','300','1','1','','','','','','',''
union all select '','M','MD','','','1','Discount','NS','@discount','','300','1','1','','','','','','',''
union all select '','M','CN','','','5','Adresa e-mail','C','@email','','300','1','1','','','','','','',''
union all select '','M','CN','','','0','ID','C','@id','','300','0','0','','','','','','',''
union all select '','M','MD','','','2','Termen','D','@termen','','','1','1','','','','','','',''
union all select '','M','MD','','','3','Cantitate','N','@cantitate','','300','1','1','',' ','','','','',''

insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
select top 0 null,null,null,null,null,null,null
union all select '9011','Sold funrizor','901','','L','SF','M'
union all select '901','Terti','900','Terti2','L','MT','M'
union all select '902','Nomenclator','900','Nomenclator','L','MN','M'
union all select '905','Comenzi','900','Contracte','L','MC','M'
union all select '904','Indicatori','900','indicatori','L','MI','M'
union all select '9012','Comanda deschisa','901','','L','CD','M'
union all select '9013','Comenzi de facturat','901','','L','CF','M'
union all select '9014','Incasare facturi','901','','L','IF','M'
union all select '9015','Incasare suma','901','','L','IS','M'
union all select '9016','Persoane contact','901','','L','PC','M'
union all select '9017','Harta terti','901','','L','HA','M'
union all select '9018','Situatii','901','','L','ST','M'
union all select '903','Bonuri','900','Bonuri','L','MB','M'
union all select '911','Rute','900','Terti2','L','RR','M'

insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','L','MT','','','1','terti','','','','wmIaTerti','','','','','','1',' ',''
union all select '','L','MB','','','1','Bonuri','','','','wmIaBonuri','','','','','','1',' ',''
union all select '','L','MC','','','2','Comenzi pentru mobil','','','','wmIaComenzi','','','','','','1',' ',''
union all select '','L','MI','','','1','indicatori','','','','wIaCategoriiTB','','','','','','1',' ',''
union all select '','L','MN','','','1','nomenclator','','','','wmNomenclator','','','','','','1',' ',''
union all select '','L','RR','','','1','rute','','','','wmIaRute','','','','','','1',' ',''

