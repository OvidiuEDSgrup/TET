
if exists (select 1 from webconfigmeniu where meniu='CN') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='CN'
delete from webconfigfiltre where meniu='CN' and (''='' or isnull(tip,'')='')
delete from webconfiggrid where meniu='CN' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='CN' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='CN' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='CN' and (''='' or isnull(TipSursa,'')='')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'CN','Contracte','CONTRACTE','contracte','D',1051.00,'','','<row><vechi><row id="1051" nume="Contracte" idparinte="1050" icoana="contracte" tipmacheta="D" meniu="CN" modul="UC" publicabil="1"/></vechi></row>',1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CN','CB','','1','Cantitate','@cantitate','N','50','4','1','0',''
union all select 'CN','CB','','1','Cod articol','@cod','C','100','2','1','0',' '
union all select 'CN','CB','','0','Curs','@curs','N','30','13','0','0',''
union all select 'CN','CB',' ','0','Data','@data','D','80','2','1','0',''
union all select 'CN','CB','','0','Denumire gestiune','@dengestiune','C','80','7','1','0',''
union all select 'CN','CB','','0','Denumire gest.prim.','@dengestiune_primitoare','C','80','9','0','0',''
union all select 'CN','CB','','0','Denumire loc de munca','@denlm','C','80','11','0','0',''
union all select 'CN','CB','','1','Periodicitate','@denperiodicitate','C','100','7','1','0',''
union all select 'CN','CB','','0','Stare','@denstare','C','50','17','1','0',''
union all select 'CN','CB','','0','Denumire tert','@dentert','C','150','4','1','0',''
union all select 'CN','CB','','1','Articol','@denumire','G','100','1','1','0',''
union all select 'CN','CB','','1','Discount','@discount','N','50','6','1','0',''
union all select 'CN','CB','','1','Explicatii','@explicatii','C','150','8','1','0',''
union all select 'CN','CB','','0','Gestiune','@gestiune','C','30','6','0','0',''
union all select 'CN','CB','','0','Gestiune primitoare','@gestiune_primitoare','C','30','8','0','0',''
union all select 'CN','CB','','0','Loc de munca','@lm','C','30','10','0','0',''
union all select 'CN','CB','','0','Numar','@numar','C','100','1','1','0',''
union all select 'CN','CB','','0','Pozitii','@pozitii','N','30','18','1','0',''
union all select 'CN','CB','','1','Pret','@pret','N','50','5','1','0',''
union all select 'CN','CB','','0','Punct livrare','@punct_livrare','C','50','5','0','0',''
union all select 'CN','CB','','0','Stare','@stare','C','50','16','0','0',''
union all select 'CN','CB','','1','Termen','@termen','D','100','3','1','0',''
union all select 'CN','CB','','0','Tert','@tert','C','50','3','0','0',''
union all select 'CN','CB','','0','Valabilitate','@valabilitate','D','80','14','1','0',''
union all select 'CN','CB','','0','Valoare','@valoare','N','50','15','1','0',''
union all select 'CN','CB','','0','Valuta','@valuta','C','30','12','0','0',''
union all select 'CN','CF','','1','Cantitate','@cantitate','N','50','3','1','0',''
union all select 'CN','CF','','1','Articol','@cod','G','50','1','1','0',''
union all select 'CN','CF','','0','Curs','@curs','N','30','13','0','0',''
union all select 'CN','CF',' ','0','Data','@data','D','80','2','1','0',''
union all select 'CN','CF','','0','Denumire gestiune','@dengestiune','C','80','7','1','0',''
union all select 'CN','CF','','0','Denumire gest.prim.','@dengestiune_primitoare','C','80','9','0','0',''
union all select 'CN','CF','','0','Denumire loc de munca','@denlm','C','80','11','0','0',''
union all select 'CN','CF','','1','Periodicitate','@denperiodicitate','C','100','6','0','0',''
union all select 'CN','CF','','0','Stare','@denstare','C','50','17','1','0',''
union all select 'CN','CF','','0','Denumire tert','@dentert','C','150','4','1','0',''
union all select 'CN','CF',' ','1','Denumire','@denumire','C','150','2','1','0',''
union all select 'CN','CF','','1','Cant. minima','@detalii_cant_minima','N','50','8','1','0',''
union all select 'CN','CF','','1','Nr. zile livrare','@detalii_nr_zile_livrare','N','50','9','1','0',''
union all select 'CN','CF','','1','Discount','@discount','N','50','5','0','0',''
union all select 'CN','CF','','1','Explicatii','@explicatii','C','150','7','1','0',''
union all select 'CN','CF','','0','Gestiune','@gestiune','C','30','6','0','0',''
union all select 'CN','CF','','0','Gestiune primitoare','@gestiune_primitoare','C','30','8','0','0',''
union all select 'CN','CF','','0','Loc de munca','@lm','C','30','10','0','0',''
union all select 'CN','CF','','0','Numar','@numar','C','100','1','1','0',''
union all select 'CN','CF','','0','Pozitii','@pozitii','N','30','18','1','0',''
union all select 'CN','CF','','1','Pret','@pret','N','50','4','1','0',''
union all select 'CN','CF','','0','Punct livrare','@punct_livrare','C','50','5','0','0',''
union all select 'CN','CF','','0','Stare','@stare','C','50','16','0','0',''
union all select 'CN','CF','','1','Termen','@termen','D','100','2','1','0',''
union all select 'CN','CF','','0','Furnizor','@tert','C','50','3','0','0',''
union all select 'CN','CF','','0','Valabilitate','@valabilitate','D','80','14','1','0',''
union all select 'CN','CF','','0','Valoare','@valoare','N','50','15','1','0',''
union all select 'CN','CF','','0','Valuta','@valuta','C','30','12','0','0',''
union all select 'CN','CL','','1','Cantitate','@cantitate','N','50','5','1','0',''
union all select 'CN','CL','','1','Cod','@cod','C','100','2','1','0',''
union all select 'CN','CL',' ','1','Cod specific','@codspecific','C','100','1','0','0',''
union all select 'CN','CL','','1','Cota tva','@cotatva','N','50','8','1','0',''
union all select 'CN','CL','','0','Curs','@curs','N','30','13','0','0',''
union all select 'CN','CL',' ','0','Data','@data','D','80','2','1','0',''
union all select 'CN','CL','','0','Denumire gestiune','@dengestiune','C','80','7','1','0',''
union all select 'CN','CL','','0','Denumire gest.prim.','@dengestiune_primitoare','C','80','9','0','0',''
union all select 'CN','CL','','0','Denumire loc de munca','@denlm','C','80','11','0','0',''
union all select 'CN','CL','','1','Periodicitate','@denperiodicitate','C','100','10','0','0',''
union all select 'CN','CL','','0','Stare','@denstare','C','50','17','1','0',''
union all select 'CN','CL','','0','Denumire tert','@dentert','C','150','4','1','0',''
union all select 'CN','CL','','1','Denumire','@denumire','C','200','3','1','0',''
union all select 'CN','CL','','1','Pret Am. Final','@detalii_pret_amanunt_final','N','100','30','1','0',''
union all select 'CN','CL','','1','Discount','@discount','N','50','9','1','0',''
union all select 'CN','CL','','1','Explicatii','@explicatii','C','150','11','0','0',''
union all select 'CN','CL','','0','Gestiune','@gestiune','C','30','6','0','0',''
union all select 'CN','CL','','0','Gestiune primitoare','@gestiune_primitoare','C','30','8','0','0',''
union all select 'CN','CL','','0','Loc de munca','@lm','C','30','10','0','0',''
union all select 'CN','CL','','0','Numar','@numar','C','100','1','1','0',''
union all select 'CN','CL','','0','Pozitii','@pozitii','N','30','18','1','0',''
union all select 'CN','CL','','1','Pret','@pret','N','50','7','1','0',''
union all select 'CN','CL','','0','Punct livrare','@punct_livrare','C','50','5','0','0',''
union all select 'CN','CL','','0','Stare','@stare','C','50','16','0','0',''
union all select 'CN','CL','','1','Termen','@termen','D','100','4','0','0',''
union all select 'CN','CL','','0','Tert','@tert','C','50','3','0','0',''
union all select 'CN','CL','','1','UM','@um','C','30','6','1','0',''
union all select 'CN','CL','','0','Valabilitate','@valabilitate','D','80','14','0','0',''
union all select 'CN','CL','','0','Valoare','@valoare','N','50','15','1','0',''
union all select 'CN','CL','','0','Valuta','@valuta','C','30','12','0','0',''
union all select 'CN','CL','CX','1','Adaos %','@adaos','C','100','4','1','0','(Math.round(((Number(row.@pret_amanunt_final)/(1+Number(row.@cotatva)/100)-Number(row.@pretstoc))/Number(row.@pretstoc))*10000)/100).toFixed(2) '
union all select 'CN','CL','CX','1','Discount %','@discount','C','100','3','1','1','(Math.round((1-(Number(row.@pret_amanunt_final)/Number(row.@pret_amanunt_lista)))*10000)/100).toFixed(2) '
union all select 'CN','CL','CX','1','Pret Am. Final','@pret_amanunt_final','C','150','2','1','1','(Math.round(Number(row.@pret_amanunt_lista)*(1-((Number(row.@discount))/100))*100)/100).toFixed(2)'
union all select 'CN','CL','CX','1','Pret Am. Lista','@pret_amanunt_lista','C','150','1','1','0',''
union all select 'CN','CL','GF','1','Cantitate','@cantitate','N','80','3','1','0',''
union all select 'CN','CL','GF','1','Cod','@cod','C','70','1','1','0',''
union all select 'CN','CL','GF','1','De facturat','@defacturat','N','100','7','1','1',''
union all select 'CN','CL','GF','1','Denumire','@denumire','C','200','2','1','0',''
union all select 'CN','CL','GF','1','Facturat','@facturat','N','80','6','1','0',''
union all select 'CN','CL','GF','1','Rezervat','@rezervat','N','80','5','1','0',''
union all select 'CN','CL','GF','1','Stoc in gest.','@stoc','N','80','4','1','0',''
union all select 'CN','CL','GR','1','Cantitate','@cantitate','N','100','3','1','0',''
union all select 'CN','CL','GR','1','Cod','@cod','C','100','1','1','0',''
union all select 'CN','CL','GR','1','Denumire','@denumire','C','250','2','1','0',''
union all select 'CN','CL','GR','1','De rezervat','@derezervat','N','100','6','1','1',''
union all select 'CN','CL','GR','1','Rezervat','@rezervat','N','100','5','1','0',''
union all select 'CN','CL','GR','1','Stoc in gest.','@stoc','N','100','4','1','0',''
union all select 'CN','CS','','1','Cantitate','@cantitate','N','50','3','1','0',''
union all select 'CN','CS','','0','Curs','@curs','N','30','13','0','0',''
union all select 'CN','CS',' ','0','Data','@data','D','80','2','1','0',''
union all select 'CN','CS','','0','Denumire gestiune','@dengestiune','C','80','7','1','0',''
union all select 'CN','CS','','0','Denumire gest.prim.','@dengestiune_primitoare','C','80','9','0','0',''
union all select 'CN','CS','','0','Denumire loc de munca','@denlm','C','80','11','0','0',''
union all select 'CN','CS','','1','Periodicitate','@denperiodicitate','C','100','6','1','0',''
union all select 'CN','CS','','0','Stare','@denstare','C','50','17','1','0',''
union all select 'CN','CS','','0','Denumire tert','@dentert','C','150','4','1','0',''
union all select 'CN','CS','','1','Articol','@denumire','G','200','1','1','0',''
union all select 'CN','CS','','1','Discount','@discount','N','50','5','1','0',''
union all select 'CN','CS','','1','Explicatii','@explicatii','C','150','7','1','0',''
union all select 'CN','CS','','0','Gestiune','@gestiune','C','30','6','0','0',''
union all select 'CN','CS','','0','Gestiune primitoare','@gestiune_primitoare','C','30','8','0','0',''
union all select 'CN','CS','','0','Loc de munca','@lm','C','30','10','0','0',''
union all select 'CN','CS','','0','Numar','@numar','C','100','1','1','0',''
union all select 'CN','CS','','0','Pozitii','@pozitii','N','30','18','1','0',''
union all select 'CN','CS','','1','Pret','@pret','N','50','4','1','0',''
union all select 'CN','CS','','0','Punct livrare','@punct_livrare','C','50','5','0','0',''
union all select 'CN','CS','','0','Stare','@stare','C','50','16','0','0',''
union all select 'CN','CS','','1','Termen','@termen','D','100','2','0','0',''
union all select 'CN','CS','','0','Tert','@tert','C','50','3','0','0',''
union all select 'CN','CS','','0','Valabilitate','@valabilitate','D','80','14','1','0',''
union all select 'CN','CS','','0','Valoare','@valoare','N','50','15','1','0',''
union all select 'CN','CS','','0','Valuta','@valuta','C','30','12','0','0',''
union all select 'CN','CS','FC','1','Cantitate','@cantitate','N','100','40','1','0',''
union all select 'CN','CS','FC','1','Den.art.facturare','@dencod','C','300','30','1','0',''
union all select 'CN','CS','FC','1','Tert','@dentert','C','250','20','1','0',''
union all select 'CN','CS','FC','1','Nr. poz.','@nr_pozitie','N','70','25','1','0',''
union all select 'CN','CS','FC','1','Contract','@numar_contract','C','100','10','1','0',''
union all select 'CN','CS','FC','1','Pret','@pret','N','100','50','1','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'CN','CB','3','0','','Denumire gest.','Denumire gestiune','@f_dengestiune','0','',''
union all select 'CN','CB','5','0','','Denumire gest.prim.','Denumire gest. prim.','@f_dengestiune_primitoare','0','',''
union all select 'CN','CB','9','0','','Denumire loc de munca','Denumire loc munca','@f_denlm','0','',''
union all select 'CN','CB','7','1','','Beneficiar','Beneficiar','@f_dentert','0','',''
union all select 'CN','CB','2','0','','Gestiune','Gestiune','@f_gestiune','0','',''
union all select 'CN','CB','4','0','','Gestiune primitoare','Gestiune primitoare','@f_gestiune_primitoare','0','',''
union all select 'CN','CB','8','0','','Loc de munca','Loc de munca','@f_lm','0','',''
union all select 'CN','CB','1','1','','Numar','Numar contract','@f_numar','0','',''
union all select 'CN','CB','10','1','','Stare','Stare contract','@f_stare','0','',''
union all select 'CN','CB','6','0','','Tert','Tert','@f_tert','0','',''
union all select 'CN','CF','3','0','','Denumire gest.','Denumire gestiune','@f_dengestiune','0','',''
union all select 'CN','CF','5','0','','Denumire gest.prim.','Denumire gest. prim.','@f_dengestiune_primitoare','0','',''
union all select 'CN','CF','9','0','','Denumire loc de munca','Denumire loc munca','@f_denlm','0','',''
union all select 'CN','CF','7','1','','Furnizor','Furnizor','@f_dentert','0','',''
union all select 'CN','CF','2','0','','Gestiune','Gestiune','@f_gestiune','0','',''
union all select 'CN','CF','4','0','','Gestiune primitoare','Gestiune primitoare','@f_gestiune_primitoare','0','',''
union all select 'CN','CF','8','0','','Loc de munca','Loc de munca','@f_lm','0','',''
union all select 'CN','CF','1','1','','Numar','Numar contract','@f_numar','0','',''
union all select 'CN','CF','10','1','','Stare','Stare contract','@f_stare','0','',''
union all select 'CN','CF','6','0','','Furnizor','Tert','@f_tert','0','',''
union all select 'CN','CL','3','0','','Denumire gest.','Denumire gestiune','@f_dengestiune','0','',''
union all select 'CN','CL','5','0','','Denumire gest.prim.','Denumire gest. prim.','@f_dengestiune_primitoare','0','',''
union all select 'CN','CL','9','0','','Denumire loc de munca','Denumire loc munca','@f_denlm','0','',''
union all select 'CN','CL','7','0','','Beneficiar','Beneficiar','@f_dentert','0','',''
union all select 'CN','CL','2','1','','Gestiune','Gestiune','@f_gestiune','0','',''
union all select 'CN','CL','4','0','','Gestiune primitoare','Gestiune primitoare','@f_gestiune_primitoare','0','',''
union all select 'CN','CL','8','0','','Loc de munca','Loc de munca','@f_lm','0','',''
union all select 'CN','CL','1','1','','Numar','Numar contract','@f_numar','0','',''
union all select 'CN','CL','10','1','','Stare','Stare contract','@f_stare','0','',''
union all select 'CN','CL','6','1','','Denumire tert','Denumire tert','@f_tert','0','',''
union all select 'CN','CS','3','0','','Denumire gest.','Denumire gestiune','@f_dengestiune','0','',''
union all select 'CN','CS','5','0','','Denumire gest.prim.','Denumire gest. prim.','@f_dengestiune_primitoare','0','',''
union all select 'CN','CS','9','0','','Denumire loc de munca','Denumire loc munca','@f_denlm','0','',''
union all select 'CN','CS','7','1','','Beneficiar','Beneficiar','@f_dentert','0','',''
union all select 'CN','CS','2','0','','Gestiune','Gestiune','@f_gestiune','0','',''
union all select 'CN','CS','4','0','','Gestiune primitoare','Gestiune primitoare','@f_gestiune_primitoare','0','',''
union all select 'CN','CS','8','0','','Loc de munca','Loc de munca','@f_lm','0','',''
union all select 'CN','CS','1','1','','Numar','Numar contract','@f_numar','0','',''
union all select 'CN','CS','10','1','','Stare','Stare contract','@f_stare','0','',''
union all select 'CN','CS','6','0','','Tert','Tert','@f_tert','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CN','CA','','2','Comenzi aprovizionare','','','','wIaContracte','','wStergContracte','wIaPozContracte','wScriuPozContracte','wStergPozContracte','0',' ','',''
union all select 'CN','CA','CA','2','Pozitie comanda','','','',' ','',' ',' ',' ',' ','1',' ','',''
union all select 'CN','CA','DC','1','Definitivare comanda','Operatia va trece comanda in starea "Definitiva" care nu va mai permite modificari asupra comenzii in conditiile in care comanda se afla in starea "Operat"','','',' ','wOPDefinitivareContract','','','','','1','O','','D'
union all select 'CN','CA','LS','5','Formular comanda','Opereaza genera un formular aferent comenzii selectate.','','','','wOPGenerareFormularComanda','','','','','1','O','','V'
union all select 'CN','CA','MA','4','Modificare contract','Operatia permite modificarea datelor de antet a comenzii. Atentie, aceste modificari dau efect direct si sunt jurnalizate!','','','','wOPModificareContract','','','','','1','O','','Z'
union all select 'CN','CB','','7','Contracte beneficiar','','','','wIaContracte',' ','wStergContracte','wIaPozContracte','wScriuPozContracte','wStergPozContracte','1',' ','',''
union all select 'CN','CB','CB','1','Pozitie contract','','','','','','','','','','1',' ','',''
union all select 'CN','CB','DC','3','Discount pe cod','','','','','','','','','','1',' ','',''
union all select 'CN','CB','DG','2','Discount grupa','','','','','','','','','','1',' ','',''
union all select 'CN','CF','','1','Contracte furnizori','','','','wIaContracte','','wStergContracte','wIaPozContracte','wScriuPozContracte','wStergPozContracte','1',' ','',''
union all select 'CN','CF','CF','1','Pozitie contract','','','','','','','','','','1',' ','',''
union all select 'CN','CL','','1','Comenzi livrare','','','','wIaContracte','','wStergContracte','wIaPozContracte','wScriuPozContracte','wStergPozContracte','0',' ','',''
union all select 'CN','CL','CL','8','Pozitie comanda','','','',' ','',' ',' ',' ',' ','1',' ','',''
union all select 'CN','CL','CX','10','Stabilire pret','','','','','wOPStabilirePret','','','','','1','O','wOPStabilirePret_p','Q'
union all select 'CN','CL','DC','1','Definitivare comanda','Operatia va trece comanda in starea "Definitiva" care nu va mai permite modificari asupra comenzii in conditiile in care comanda se afla in starea "Operat"','','',' ','wOPDefinitivareContract','','','','','1','O','','D'
union all select 'CN','CL','GF','3','Generare factura','Operatia genereaza o factura cu pozitiile aferente si cantitatile modificabile din coloana "De facturat". Stocurile se vor descarca in urmatoarea ordine: daca exista rezervari pe comanda se va descarca gestiunea de rezervari, urmand ca diferentele (daca exista) sa fie descarcate din gestiunea comenzii.','','','','wOPGenerareFactura','','','','','1','O','wOPGenerareFactura_p','F'
union all select 'CN','CL','GR','2','Generare rezervare','Operatia genereaza un transfer catre gestiunea de rezervari setata, luand in calcul coloana modificabila "de rezervat". Rezervarile vor fi vizibile in tab-ul de Rezervari de pe comanda.','','','','wOPGenerareRezervare','','','','','1','O','wOPGenerareRezervare_p','G'
union all select 'CN','CL','LS','5','Formular comanda','Opereaza genera un formular aferent comenzii selectate.','','','','wOPGenerareFormularComanda','','','','','1','O','','V'
union all select 'CN','CL','MA','4','Modificare contract','Operatia permite modificarea datelor de antet a comenzii. Atentie, aceste modificari dau efect direct si sunt jurnalizate!','','','','wOPModificareContract','','','','','1','O','','Z'
union all select 'CN','CS','','3','Contracte servicii','','','','wIaContracte','','wStergContracte','wIaPozContracte','wScriuPozContracte','wStergPozContracte','1',' ','',''
union all select 'CN','CS','AB','2','Abonament','','','','','','','','','','1',' ','',''
union all select 'CN','CS','CS','1','Serviciu','','','','','','','','','','1',' ','',''
union all select 'CN','CS','FC','9','Generare facturi','','','','','wOPFacturareContracte','','','','','0','O','wOPFacturareContracte_p',''
union all select 'CN','CS','VV','10','Facturare contracte','','','','','wOPFactContractePrePopulare','','','','','1','O','wOPFactContractePrePopulare_p','F'
union all select 'CN','FP','','5','Facturi proforma','','','','','','','','','','0',' ','',''
union all select 'CN','OF','','6','Oferte furnizori','','','','','','','','','','0',' ','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CN','CB','','9','Curs','N','@curs','','50','0','1','','','','','','','',''
union all select 'CN','CB','','2','Data','D','@data',' ','100','1','1','','','','','','','',''
union all select 'CN','CB','','20','Discount','N','@detalii_discount','','100','1','1','','','','','Discount pe tert','','',''
union all select 'CN','CB','','11','Explicatii','T','@explicatii','','200','1','1','','','','','','','',''
union all select 'CN','CB','','10','Gestiune','AC','@gestiune','@dengestiune','200','1','1','wACGestiuni','','','','Gestiune','','',''
union all select 'CN','CB','','6','Gestiune primitoare','AC','@gestiune_primitoare','@dengestiune_primitoare','200','0','1','wACGestiuni','','','','Gestiune primitoare','','',''
union all select 'CN','CB','','7','Loc de munca','AC','@lm','@denlm','200','1','1','wACLocm','','','','Loc de munca','','',''
union all select 'CN','CB','','1','Numar','C','@numar',' ','100','0','1','','','','','','','',''
union all select 'CN','CB','','4','Punct livrare','AC','@punct_livrare','@denpunct_livrare','200','0','1','wACPuncteLivrare','','','','Punct livrare','','',''
union all select 'CN','CB','','3','Tert','AC','@tert','@dentert','200','1','1','wACTerti','','','','Beneficiar','','',''
union all select 'CN','CB','','5','Valabilitate','D','@valabilitate',' ','100','1','1','','','','','','','',''
union all select 'CN','CB','','8','Valuta','AC','@valuta','@denvaluta','200','0','1','wACValuta','','','','Valuta','','',''
union all select 'CN','CB','CB','2','Cantitate','N','@cantitate',' ','50','1','1','','','','','','','',''
union all select 'CN','CB','CB','1','Cod','AC','@cod','@dencod','250','1','1','wACNomenclator','','','','Articol','','',''
union all select 'CN','CB','CB','4','Discount','N','@discount',' ','50','1','1','','','','','','','',''
union all select 'CN','CB','CB','7','Explicatii','C','@explicatii','','200','1','1','','','','','','','',''
union all select 'CN','CB','CB','6','Periodicitate','CB','@periodicitate','','120','1','1','','0,1,2,3,4,6,12','Fara periodicitate,Lunar,2 luni,Trimestrial,4 luni,Semestrial,Anual','0','','','',''
union all select 'CN','CB','CB','3','Pret','N','@pret',' ','50','1','1','','','','','','','',''
union all select 'CN','CB','CB','5','Termen','D','@termen',' ','100','1','1','','','','','','','',''
union all select 'CN','CB','DC','1','Cod','AC','@cod','','200','1','1','wACNomenclator','','','','Cod articol','','',''
union all select 'CN','CB','DC','2','Discount','N','@discount','','100','1','1','','','','','','','',''
union all select 'CN','CB','DG','2','Discount','N','@discount','','100','1','1','','','','','','','',''
union all select 'CN','CB','DG','1','Cod','AC','@grupa','','200','1','1','wACGrupe','','','','Cod grupa','','',''
union all select 'CN','CF','','9','Curs','N','@curs','','50','1','1','','','','','','','',''
union all select 'CN','CF','','2','Data','D','@data',' ','100','1','1','','','','','','','',''
union all select 'CN','CF','','11','Explicatii','T','@explicatii','','200','1','1','','','','','','','',''
union all select 'CN','CF','','10','Gestiune','AC','@gestiune','@dengestiune','200','1','1','wACGestiuni','','','','Gestiune','','',''
union all select 'CN','CF','','6','Gestiune primitoare','AC','@gestiune_primitoare','@dengestiune_primitoare','200','0','1','wACGestiuni','','','','Gestiune primitoare','','',''
union all select 'CN','CF','','7','Loc de munca','AC','@lm','@denlm','200','1','1','wACLocm','','','','Loc de munca','','',''
union all select 'CN','CF','','1','Numar','C','@numar',' ','100','0','1','','','','','','','',''
union all select 'CN','CF','','4','Punct livrare','AC','@punct_livrare','@denpunct_livrare','200','0','1','wACPuncteLivrare','','','','Punct livrare','','',''
union all select 'CN','CF','','3','Furnizor','AC','@tert','@dentert','200','1','1','wACTerti','','','','Furnizor','','',''
union all select 'CN','CF','','5','Valabilitate','D','@valabilitate',' ','100','0','1','','','','','','','',''
union all select 'CN','CF','','8','Valuta','AC','@valuta','@denvaluta','200','1','1','wACValuta','','','','Valuta','','',''
union all select 'CN','CF','CF','3','Cantitate','N','@cantitate',' ','50','1','1','','','','','','','',''
union all select 'CN','CF','CF','1','Cod','AC','@cod','@dencod','250','1','1','wACNomenclator','','','','Articol','','',''
union all select 'CN','CF','CF','2','Cod specific','C','@codspecific','','150','1','1','','','','','','','',''
union all select 'CN','CF','CF','9','Cant. minima','N','@detalii_cant_minima','','50','1','1','','','','','','','',''
union all select 'CN','CF','CF','10','Nr. zile livrare','N','@detalii_nr_zile_livrare','','50','1','1','','','','','','','',''
union all select 'CN','CF','CF','5','Discount','N','@discount',' ','50','0','1','','','','','','','',''
union all select 'CN','CF','CF','8','Explicatii','C','@explicatii','','200','1','1','','','','','','','',''
union all select 'CN','CF','CF','7','Periodicitate','CB','@periodicitate','','120','0','1','','0,1,2,3,4,6,12','Fara periodicitate,Lunar,2 luni,Trimestrial,4 luni,Semestrial,Anual','0','','','',''
union all select 'CN','CF','CF','4','Pret','N','@pret',' ','50','1','1','','','','','','','',''
union all select 'CN','CF','CF','6','Termen','D','@termen',' ','100','1','1','','','','','','','',''
union all select 'CN','CL','','10','Curs','N','@curs','','50','0','1','','','','','','','',''
union all select 'CN','CL','','2','Data','D','@data',' ','100','1','1','','','','','','','',''
union all select 'CN','CL','','12','Responsabil','C','@detalii_responsabil','','150','1','1','','','','','Persoana','','',''
union all select 'CN','CL','','11','Explicatii','T','@explicatii','','200','1','1','','','','','','','',''
union all select 'CN','CL','','3','Gestiune','AC','@gestiune','@dengestiune','200','1','1','wACGestiuni','','','','Gestiune','','',''
union all select 'CN','CL','','8','Gestiune primitoare','AC','@gestiune_primitoare','@dengestiune_primitoare','200','1','1','wACGestiuni','','','','Gestiune primitoare','','',''
union all select 'CN','CL','','20','Contract','AC','@idContractCorespondent','@denidContractCorespondent','250','1','1','wACContracteBeneficiar','','','','Contractul corespondent...','','',''
union all select 'CN','CL','','7','Loc de munca','AC','@lm','@denlm','200','1','1','wACLocm','','','','Loc de munca','','',''
union all select 'CN','CL','','1','Numar','C','@numar',' ','100','1','1','','','','','','','',''
union all select 'CN','CL','','5','Punct livrare','AC','@punct_livrare','@denpunct_livrare','200','1','1','wACPuncteLivrare','','','','Punct livrare','','',''
union all select 'CN','CL','','4','Tert','AC','@tert','@dentert','200','1','1','wACTerti','','','','Tert','','',''
union all select 'CN','CL','','6','Valabilitate','D','@valabilitate',' ','100','0','1','','','','','','','',''
union all select 'CN','CL','','9','Valuta','AC','@valuta','@denvaluta','200','0','1','wACValuta','','','','Valuta','','',''
union all select 'CN','CL','CL','2','Cantitate','N','@cantitate',' ','50','1','1','','','','','','','',''
union all select 'CN','CL','CL','1','Cod','AC','@cod','@dencod','350','1','1','wACNomenclator','','','','Articol','','',''
union all select 'CN','CL','CL','1','Cod specific','AC','@codspecific','@dencodspecific','200','0','1','wACNomSpecif','','','','Articol specific','','',''
union all select 'CN','CL','CL','4','Discount','N','@discount',' ','50','0','1','','','','','','','',''
union all select 'CN','CL','CL','7','Explicatii','C','@explicatii','','200','0','1','','','','','','','',''
union all select 'CN','CL','CL','6','Periodicitate','CB','@periodicitate','','120','0','1','','0,1,2,3,4,6,12','Fara periodicitate,Lunar,2 luni,Trimestrial,4 luni,Semestrial,Anual','0','','','',''
union all select 'CN','CL','CL','3','Pret','N','@pret',' ','50','0','1','','','','','','','',''
union all select 'CN','CL','CL','5','Termen','D','@termen',' ','100','0','1','','','','','','','',''
union all select 'CN','CL','CX','1','Cod produs','C','@cod','','100','1','0','','','','','','','',''
union all select 'CN','CL','CX','2','Denumire produs','C','@dencod_produs','','300','1','0','','','','','','','',''
union all select 'CN','CL','CX','3','Pret ultima achizitie','N','@pret_stoc','','150','1','0','','','','','','','',''
union all select 'CN','CL','DC','1','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'CN','CL','GF','1','Data factura','D','@data','','200','1','1','','','','','','','',''
union all select 'CN','CL','GF','7','Eliberat','C','@eliberat','','200','1','1','','','','','','','',''
union all select 'CN','CL','GF','3','Mijloc transp.','C','@mijloctransport','','200','1','1','','','','','','','',''
union all select 'CN','CL','GF','4','Numar mij.transp.','C','@nrmijloctransport','','200','1','1','','','','','','','',''
union all select 'CN','CL','GF','6','Numar buletin','C','@numarbuletin','','100','1','1','','','','','','','',''
union all select 'CN','CL','GF','2','Delegat','C','@numedelegat','','200','1','1','','','','','','','',''
union all select 'CN','CL','GF','8','Observatii','C','@observatii','','200','1','1','','','','','','','',''
union all select 'CN','CL','GF','5','Seria buletin','C','@seriabuletin','','100','1','1','','','','','','','',''
union all select 'CN','CL','GR','1','Data','D','@data','','200','1','1','','','','','','','',''
union all select 'CN','CL','GR','4','Gestiune','C','@dengestiune','','100','1','0','','','','','','','',''
union all select 'CN','CL','GR','2','Beneficiar','C','@dentert','','200','1','0','','','','','','','',''
union all select 'CN','CL','GR','5','Gestiune rezervari','C','@gestiunerezervari','','100','1','0','','','','','','','',''
union all select 'CN','CL','GR','3','Comanda','C','@numar','','100','1','0','','','','','','','',''
union all select 'CN','CL','LS','1','Data listare','D','@data','','200','1','0','','','','','','','',''
union all select 'CN','CL','MA','9','Curs','N','@curs','','50','1','1','','','','','','','',''
union all select 'CN','CL','MA','2','Data','D','@data','','200','1','1','','','','','','','',''
union all select 'CN','CL','MA','11','Responsabil','C','@detalii_responsabil','','150','1','1','','','','','Resp.','','',''
union all select 'CN','CL','MA','10','Explicatii','T','@explicatii','','200','1','1','','35','',' ','','','',''
union all select 'CN','CL','MA','6','Gestiune','AC','@gestiune','@dengestiune','200','1','1','wACGestiuni','','','','Gestiune','','',''
union all select 'CN','CL','MA','7','Gestiune primitoare','AC','@gestiune_primitoare','@dengestiune_primitoare','200','1','1','wACGestiuni','','','','Gestiune primitoare','','',''
union all select 'CN','CL','MA','5','Loc munca','AC','@lm','@denlm','200','1','1','wACLocm','','','','Loc munca','','',''
union all select 'CN','CL','MA','1','Contract','C','@numar','','200','1','0','','','','','','','',''
union all select 'CN','CL','MA','4','Punct livrare','AC','@punct_livrare','@denpunct_livrare','200','1','1','wACPuncteLivrare','','','','Punct livrare','','',''
union all select 'CN','CL','MA','3','Tert','AC','@tert','@dentert','200','1','1','wACTerti','','','','Tert','','',''
union all select 'CN','CL','MA','8','Valuta','AC','@valuta','@denvaluta','200','1','1','wACValuta','','','','Valuta','','',''
union all select 'CN','CS','','9','Curs','N','@curs','','50','0','1','','','','','','','',''
union all select 'CN','CS','','2','Data','D','@data',' ','100','1','1','','','','','','','',''
union all select 'CN','CS','','11','Explicatii','T','@explicatii','','200','1','1','','','','','','','',''
union all select 'CN','CS',' ','6','Gestiune','AC','@gestiune','@dengestiune','250','0','1','wACGestiuni','','','','Gestiunea...','','',''
union all select 'CN','CS','','7','Loc de munca','AC','@lm','@denlm','200','1','1','wACLocm','','','','Loc de munca','','',''
union all select 'CN','CS','','1','Numar','C','@numar',' ','100','0','1','','','','','','','',''
union all select 'CN','CS','','4','Punct livrare','AC','@punct_livrare','@denpunct_livrare','200','0','1','wACPuncteLivrare','','','','Punct livrare','','',''
union all select 'CN','CS','','3','Tert','AC','@tert','@dentert','200','1','1','wACTerti','','','','Beneficiar','','',''
union all select 'CN','CS','','5','Valabilitate','D','@valabilitate',' ','100','1','1','','','','','','','',''
union all select 'CN','CS','','8','Valuta','AC','@valuta','@denvaluta','200','1','1','wACValuta','','','','Valuta','','',''
union all select 'CN','CS','AB','12','Cantitate','N','@cantitate','','100','1','1','','','','','','','',''
union all select 'CN','CS','AB','11','Cod','AC','@cod','@dencod','250','1','1','wACNomenclator','','','','Alegeti codul ...','','',''
union all select 'CN','CS','AB','15','Data inc.','D','@detalii_data_start','','110','1','1','','','','','','','',''
union all select 'CN','CS','AB','14','Periodicitate(luni)','CB','@periodicitate','','120','1','1','','0,1,2,3,4,6,12','Fara periodicitate,Lunar,2 luni,Trimestrial,4 luni,Semestrial,Anual','0','','','',''
union all select 'CN','CS','AB','13','Pret','N','@pret','','100','1','1','','','','','','','',''
union all select 'CN','CS','CS','2','Cantitate','N','@cantitate',' ','50','1','1','','','','','','','',''
union all select 'CN','CS','CS','1','Cod','AC','@cod','@dencod','250','1','1','wACNomenclator','','','','Articol','','',''
union all select 'CN','CS','CS','4','Discount','N','@discount',' ','50','1','1','','','','','','','',''
union all select 'CN','CS','CS','7','Explicatii','C','@explicatii','','200','1','1','','','','','','','',''
union all select 'CN','CS','CS','6','Periodicitate','CB','@periodicitate','','120','0','1','','0,1,2,3,4,6,12','Fara periodicitate,Lunar,2 luni,Trimestrial,4 luni,Semestrial,Anual','0','','','',''
union all select 'CN','CS','CS','3','Pret','N','@pret',' ','50','1','1','','','','','','','',''
union all select 'CN','CS','CS','5','Termen','D','@termen',' ','100','1','1','','','','','','','',''
union all select 'CN','CS','FC','21','Curs','N','@curs','','100','1','1','','','','','','','',''
union all select 'CN','CS','FC','15','Data facturilor','D','@data_facturii',' ','120','1','1','','','','','','','',''
union all select 'CN','CS','FC','17','Data inf.','D','@datajos','','120','1','0','','','','','','','',''
union all select 'CN','CS','FC','18','Data sup.','D','@datasus','','120','1','0','','','','','','','',''
union all select 'CN','CS','FC','30','Formular','AC','@nrform','@dennrfom','350','1','1','wACFormulare','','','','','','',''
union all select 'CN','CS','FC','20','Valuta','C','@valuta','','100','1','0','','','','','','','',''
union all select 'CN','CS','VV','17','Data inf.','D','@datajos','','120','1','1','','','','','','','',''
union all select 'CN','CS','VV','18','Data sup.','D','@datasus','','120','1','1','','','','','','','',''
union all select 'CN','CS','VV','29','Gestiune','AC','@gestiune','@dengestiune','350','1','1','wACGestiuni','','','','Gestiune...','','',''
union all select 'CN','CS','VV','32','Un contract','AC','@idContract','@dencontract','350','1','1','wACContracteNoi','','','','Un contract..','','',''
union all select 'CN','CS','VV','25','Loc munca','AC','@lm','@denlm','350','1','1','wACLocm','','','','Loc munca...','','',''
union all select 'CN','CS','VV','20','Tert','AC','@tert','@dentert','350','1','1','wACTerti','','','','Tert...','','',''
union all select 'CN','CS','VV','13','Tip contracte','CB','@tip','@dentip','250','1','1','','CS,CB','Contracte servicii,Contracte beneficiari','CS','','','',''
union all select 'CN','CS','VV','19','Valuta','AC','@valuta','','200','1','1','wACValuta','','','','Valuta','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'CN','CB','Comenzi livrare','','D','CN','CL','wIaContracte_p','9','1'
union all select 'CN','CB','Contract','','PozDoc','CN','CB','','1','1'
union all select 'CN','CB','Documente contract','','C','RA','RA','','3','1'
union all select 'CN','CB','Fisiere contract','','C','FF','FF','','4','1'
union all select 'CN','CB','Jurnal contract','','D','JB','JB','','2','1'
union all select 'CN','CF','Contract','','PozDoc','CN','CF','','1','1'
union all select 'CN','CF','Jurnal contract','','D','JB','JB','','2','1'
union all select 'CN','CS','Contract','','PozDoc','CN','CS','','1','1'
union all select 'CN','CS','Documente contract','','C','RA','RA','','2','1'
union all select 'CN','CS','Fisiere contract','','C','FF','FF','','3','1'
union all select 'CN','CS','Jurnal contract','','D','JB','JB','','4','1'
GO
--Tab: Fisiere contract ---- C ,FF, FF

if exists (select 1 from webconfigmeniu where meniu='FF') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='C' and meniu='FF'
delete from webconfigfiltre where meniu='FF' and (''='' or isnull(tip,'')='')
delete from webconfiggrid where meniu='FF' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='FF' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='FF' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='FF' and (''='' or isnull(TipSursa,'')='')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'FF','','','0','Descarcare','@download','HTML','100','3','1','0',''
union all select 'FF','','','0','Fisier','@fisier','C','100','1','1','0',''
union all select 'FF','','','0','Observatii','@observatii','HTML','200','2','1','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'FF','','','1','Fisiere atasate','Se selecteaza un fisier de pe calculatorul local, iar acesta va fi <b> incarcat </b> pe server, fiind apoi disponibil pentru <b> descarcare </b> din lista de Fisiere contract.','Adaugare fisier la contract','','wIaFisiereAtasate','wScriuFisiereAtasate','wStergFisiereAtasate','','','','1',' ','','B'

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'FF','','','1','Fisier','IN','@fisier','','200','1','1','','1','','','','','',''
union all select 'FF','','','2','Observatii','C','@observatii','','300','1','1','','','','','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null 
GO
--Tab: Documente contract ---- C ,RA, RA

if exists (select 1 from webconfigmeniu where meniu='RA') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='C' and meniu='RA'
delete from webconfigfiltre where meniu='RA' and (''='' or isnull(tip,'')='')
delete from webconfiggrid where meniu='RA' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='RA' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='RA' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='RA' and (''='' or isnull(TipSursa,'')='')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'RA','','','0','Cantitate','@cantitate','N','50','7','1','0',''
union all select 'RA','','','0','Cod','@cod','C','60','4','1','0',''
union all select 'RA','','','0','Cod intrare','@codintrare','C','100','5','1','0',''
union all select 'RA','','','0','Data','@data','D','70','3','1','0',''
union all select 'RA','','','0','Denumire','@denumire','C','150','6','1','0',''
union all select 'RA','','','0','Numar doc.','@numardoc','C','60','2','1','0',''
union all select 'RA','','','0','Tip document','@tipdocument','C','70','1','1','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'RA','RA','1','1','','Cod','Cod','@f_cod','0','',''
union all select 'RA','RA','2','1','','Denumire','Denumire','@f_denumire','0','',''
union all select 'RA','RA','3','1','','Numar doc','Numar doc','@f_numardoc','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'RA','','','1','Documente comanda','','','','wIaDocumenteComanda',' ','wStergDocumenteComanda','','','','1',' ','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null 
GO
--Tab: Jurnal contract ---- D ,JB, JB

if exists (select 1 from webconfigmeniu where meniu='JB') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='JB'
delete from webconfigfiltre where meniu='JB' and ('JB'='' or isnull(tip,'')='JB')
delete from webconfiggrid where meniu='JB' and ('JB'='' or isnull(tip,'')='JB') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='JB' and ('JB'='' or isnull(tip,'')='JB') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='JB' and ('JB'='' or isnull(tip,'')='JB') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='JB' and ('JB'='' or isnull(TipSursa,'')='JB')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','','0','Data','@data','C','100','1','1','0',''
union all select 'JB','JB','','0','Denumire stare','@denstare','C','100','3','1','0',''
union all select 'JB','JB','','0','Explicatii','@explicatii','C','150','5','1','0',''
union all select 'JB','JB','','0','Stare','@stare','C','50','2','1','0',''
union all select 'JB','JB','','0','Utilizator','@utilizator','C','100','4','1','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','2','1','','Denumire stare','Denumire stare','@f_denstare','0','',''
union all select 'JB','JB','1','1','','Stare','Stare','@f_stare','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'JB','JB','','1','Jurnal contract','','','','wIaJurnalContract','','','','','','1',' ','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null 