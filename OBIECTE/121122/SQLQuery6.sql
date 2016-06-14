--/*
if exists (select 1 from webconfigmeniu where tipMacheta='O' and meniu='YN') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--*/delete from webconfigmeniu where tipMacheta='O' and meniu='YN'
delete from webconfiggrid where tipMacheta='O' and meniu='YN' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigfiltre where tipMacheta='O' and meniu='YN' and (''='' or isnull(tip,'')='')
delete from webconfigtipuri where tipMacheta='O' and meniu='YN' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where tipMacheta='O' and meniu='YN' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
insert into webconfigmeniu(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
select top 0 null,null,null,null,null,null,null
union all select '331','Generare declaratie 300','3','Generare declaratie 300','O','YN',''

insert into webconfigTipuri (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','O','YN','','','331','Generare decl. 300','Generare decont de TVA (declaratia 300) in format XML pt. prelucrare ulterioara cu aplicatia ANAF.','','','','wOPGenerareD300','','','','','0','O','wOPGenerareD300_p'

insert into webconfigFiltre (IdUtilizator, TipMacheta, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfiggrid (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, Ordine, NumeCol, DataField, TipObiect, Latime, Vizibil) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select '','O','YN','','','0','1','Data','@data','C','100','1'
union all select '','O','YN','','','0','2','Rand decont','@randdecont','C','100','1'
union all select '','O','YN','','','0','3','Denumire indicator','@denindicator','C','300','1'
union all select '','O','YN','','','0','4','Valoare','@valoare','C','100','1'
union all select '','O','YN','','','0','5','TVA','@tva','C','100','1'

insert into webconfigForm (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select '','O','YN','','','1','Luna','CB','@luna','','100','1','1','','1,2,3,4,5,6,7,8,9,10,11,12','Ianuarie,Februarie,Martie,Aprilie,Mai,Iunie,Iulie,August,Septembrie,Octombrie,Noiembrie,Decembrie','1','Luna pentru generare declaratie','',''
union all select '','O','YN','','','2','An','CB','@an','','100','1','1','','2011,2012,2013,2014,2015,2016,2017,2018,2019,2020','2011,2012,2013,2014,2015,2016,2017,2018,2019,2020','2012','Anul pentru generare declaratie','',''
union all select '','O','YN','','','3','Tip declaratie','CB','@tipdecl','','100','1','1','','L,T,S,A','Lunara,Trimestriala,Semestriala,Anuala','L','','',''
union all select '','O','YN','','','4','Metoda simplificata pt. operatiuni interne','CHB','@bifa_interne','','250','1','1','','','','','Metoda simplificata pt. operatiuni interne','',''
union all select '','O','YN','','','5','Solicitare rambursare de TVA','CHB','@ramburstva','','250','1','1','','','','','Daca se solicita rambursare de TVA','',''
union all select '','O','YN','','','6','Pro rata de deducere %','N','@prorata','','60','1','1','','','','','Pro rata de deducere (%)','',''
union all select '','O','YN','','','7','Optiuni generare','CB','@optiunigenerare','','200','1','1','','0,1','Calcul si generare fisier XML,Generare fisier XML','0','Optiuni de generare a declaratiei','',''
union all select '','O','YN','','','8','Functie declarant','C','@functiedecl','','250','1','1','','','','','Functie persoana autorizata','',''
union all select '','O','YN','','','9','Nume declarant','C','@numedecl','','250','1','1','','','','','Nume persoana autorizata','',''
union all select '','O','YN','','','10','Prenume declarant','C','@prendecl','','250','1','1','','','','','Prenume persoana autorizata','',''