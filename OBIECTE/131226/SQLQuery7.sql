
if exists (select 1 from webconfigmeniu where meniu='DO') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='DO'
delete from webconfigfiltre where meniu='DO' and ('AC'='' or isnull(tip,'')='AC')
delete from webconfiggrid where meniu='DO' and ('AC'='' or isnull(tip,'')='AC') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='DO' and ('AC'='' or isnull(tip,'')='AC') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='DO' and ('AC'='' or isnull(tip,'')='AC') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='DO' and ('AC'='' or isnull(TipSursa,'')='AC')

--insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
--				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
--select top 0 null,null,null,null,null,null,null,null,null,null
--union all select 'DO','Intrari/Iesiri','GESTIUNE','Intrari iesiri','D',11.00,'','','<row><vechi><row id="11" nume="Intrari/Iesiri" idparinte="1" icoana="Intrari iesiri" tipmacheta="D" meniu="DO" modul="1" publicabil="1"/></vechi></row>',1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AC','','1','Adaos','@adaos','N','50','16','0','0',''
union all select 'DO','AC','','1','Barcod','@barcod','C','50','31','0','0',''
union all select 'DO','AC','','1','Cantitate','@cantitate','N','80','3','1','0',''
union all select 'DO','AC','','0','Categ.pret','@categpret','N','50','21','0','0',''
union all select 'DO','AC','','1','Categ. pret','@categpret','N','50','34','0','0',''
union all select 'DO','AC','','1','Cod','@cod','C','60','1','1','0',''
union all select 'DO','AC','','1','Cod intrare','@codintrare','C','100','4','1','0',''
union all select 'DO','AC','','0','Comanda','@comanda','C','50','11','0','0',''
union all select 'DO','AC','','1','Comanda','@comanda','C','80','12','0','0',''
union all select 'DO','AC','','0','Cont coresp.','@contcorespondent','C','50','30','0','0',''
union all select 'DO','AC','','1','Cont coresp.','@contcorespondent','N','80','32','0','0',''
union all select 'DO','AC','','0','Cont factura','@contfactura','C','50','28','0','0',''
union all select 'DO','AC','','1','Cont factura','@contfactura','C','80','28','0','0',''
union all select 'DO','AC','','1','Cont intermediar','@contintermediar','C','60','35','0','0',''
union all select 'DO','AC','','0','Contract','@contract','C','80','8','0','0',''
union all select 'DO','AC','','1','Contract','@contract','N','80','22','0','0',''
union all select 'DO','AC','','1','Cont stoc','@contstoc','C','80','18','0','0',''
union all select 'DO','AC','','0','Cont venituri','@contvenituri','C','50','32','0','0',''
union all select 'DO','AC','','0','Cota Tva','@cotatva','N','50','22','0','0',''
union all select 'DO','AC','','1','TVA','@cotatva','N','60','6','1','0',''
union all select 'DO','AC','','1','Culoare','@culoare','C','80','44','0','0',''
union all select 'DO','AC','','0','Curs','@curs','N','40','16','0','0',''
union all select 'DO','AC','','1','Curs','@curs','N','50','20','0','0',''
union all select 'DO','AC','','0','Data','@data','D','100','2','1','0',''
union all select 'DO','AC','','1','Data','@data','D','100','2','0','0',''
union all select 'DO','AC','','0','Data expedierii','@dataexpedierii','D','100','48','0','0',''
union all select 'DO','AC','','1','Data expirarii','@dataexpirarii','D','100','25','0','0',''
union all select 'DO','AC','','0','Data facturii','@datafacturii','D','100','34','0','0',''
union all select 'DO','AC','','0','Data scadentei','@datascadentei','D','100','35','0','0',''
union all select 'DO','AC','','1','Den. loc munca','@demlm','C','150','41','0','0',''
union all select 'DO','AC','','1','Den.cod intrare','@dencodintrare','C','100','36','0','0',''
union all select 'DO','AC','','0','Den.comanda','@dencomanda','C','150','12','0','0',''
union all select 'DO','AC','','1','Den. comanda','@dencomanda','C','150','42','0','0',''
union all select 'DO','AC','','0','Den.cont coresp.','@dencontcorespondent','C','150','31','0','0',''
union all select 'DO','AC','','0','Den.cont factura','@dencontfact','C','150','29','0','0',''
union all select 'DO','AC','','0','Den.cont venituri','@dencontvenituri','C','150','33','0','0',''
union all select 'DO','AC','','0','Den. gestiune','@dengestiune','C','200','6','0','0',''
union all select 'DO','AC','','1','Den.gestiune','@dengestiune','C','150','37','0','0',''
union all select 'DO','AC','','0','Den.gest.prim','@dengestprim','C','150','14','0','0',''
union all select 'DO','AC','','1','Den.gest.prim','@dengestprim','C','150','39','0','0',''
union all select 'DO','AC','','0','Den. loc munca','@denlm','C','200','10','0','0',''
union all select 'DO','AC','','0','Den.pct.livrare','@denpunctlivrare','C','150','39','0','0',''
union all select 'DO','AC','','0','Denumire tert','@dentert','C','200','4','1','0',''
union all select 'DO','AC','','1','Den. tert','@dentert','C','150','43','0','0',''
union all select 'DO','AC','','1','Denumire','@denumire','C','220','2','1','0',''
union all select 'DO','AC','','0','Discount','@discount','N','50','23','0','0',''
union all select 'DO','AC','','1','Discount','@discount','N','60','29','0','0',''
union all select 'DO','AC','','1','DVI','@dvi','C','60','33','0','0',''
union all select 'DO','AC','','0','Eliberat','@eliberat','C','100','45','0','0',''
union all select 'DO','AC','','0','Explicatii','@explicatii','C','200','36','0','0',''
union all select 'DO','AC','','1','Explicatii','@explicatii','C','150','26','0','0',''
union all select 'DO','AC','','0','Factura','@factura','C','120','7','0','0',''
union all select 'DO','AC','','1','Factura','@factura','C','80','23','0','0',''
union all select 'DO','AC','','0','Gestiune','@gestiune','C','100','5','1','0',''
union all select 'DO','AC','','0','Gest. prim','@gestprim','C','50','13','0','0',''
union all select 'DO','AC','','1','Gest.prim.','@gestprim','C','80','9','0','0',''
union all select 'DO','AC','','0','Jurnal','@jurnal','C','50','37','0','0',''
union all select 'DO','AC','','1','Jurnal','@jurnal','C','50','27','0','0',''
union all select 'DO','AC','','0','Loc munca','@lm','C','100','9','1','0',''
union all select 'DO','AC','','1','Loc munca','@lm','C','80','11','0','0',''
union all select 'DO','AC','','1','Locatie','@locatie','C','50','21','0','0',''
union all select 'DO','AC','','1','Lot','@lot','C','50','24','0','0',''
union all select 'DO','AC','','0','Mijloc transp.','@mijloctp','C','40','46','0','0',''
union all select 'DO','AC','','0','Nr.mijloc transp.','@nrmijloctp','C','100','47','0','0',''
union all select 'DO','AC','','0','Numar','@numar','C','100','1','1','0',''
union all select 'DO','AC','','0','Nr. buletin','@numarbuletin','C','30','44','0','0',''
union all select 'DO','AC','','0','Numar DVI','@numardvi','C','50','27','0','0',''
union all select 'DO','AC','','1','Nr.pozitie','@numarpozitie','C','50','17','0','0',''
union all select 'DO','AC','','0','Pozitii','@numarpozitii','N','80','40','1','0',''
union all select 'DO','AC','','0','Nume delegat','@numedelegat','C','150','42','0','0',''
union all select 'DO','AC','','0','Observatii','@observatii','C','200','50','0','0',''
union all select 'DO','AC','','0','Ora expedierii','@oraexpedierii','C','50','49','0','0',''
union all select 'DO','AC','','1','Pret amanunt','@pamanunt','N','80','15','0','0',''
union all select 'DO','AC','','0','Proforma','@proforma','C','50','25','0','0',''
union all select 'DO','AC','','1','Pret de stoc','@pstoc','N','110','5','0','0',''
union all select 'DO','AC','','0','Pct.livrare','@punctlivrare','C','50','38','0','0',''
union all select 'DO','AC','','1','Punct livrare','@punctlivrare','N','80','30','0','0',''
union all select 'DO','AC','','0','Pct.livr.exped.','@punctlivrareexped','C','100','51','0','0',''
union all select 'DO','AC','','1','Pret valuta','@pvaluta','N','80','13','0','0',''
union all select 'DO','AC','','1','Pret vanzare','@pvanzare','N','80','5','1','0',''
union all select 'DO','AC','','0','Seria buletin','@seriabuletin','C','10','43','0','0',''
union all select 'DO','AC','','0','Stare','@stare','N','20','41','0','0',''
union all select 'DO','AC','','0','Suma discount','@sumadiscount','N','50','24','0','0',''
union all select 'DO','AC','','1','Suma TVA','@sumatva','N','110','7','1','0',''
union all select 'DO','AC','','0','Tert','@tert','C','100','3','0','0',''
union all select 'DO','AC','','1','Tert','@tert','C','80','10','0','0',''
union all select 'DO','AC','','1','Tip gest.','@tipgestiune','C','50','38','0','0',''
union all select 'DO','AC','','1','Tip gest.prim','@tipgestprim','C','50','40','0','0',''
union all select 'DO','AC','','0','Tip miscare','@tipmiscare','C','10','26','0','0',''
union all select 'DO','AC','','0','TVA','@tva11','N','40','17','0','0',''
union all select 'DO','AC','','0','Tva','@tva22','N','40','18','0','0',''
union all select 'DO','AC','','1','UM','@um','C','50','4','1','0',''
union all select 'DO','AC','','0','Valoare valuta','@valoarevaluta','N','50','20','0','0',''
union all select 'DO','AC','','0','Valoare','@valtotala','N','100','19','1','0',''
union all select 'DO','AC','','0','Valuta','@valuta','C','40','15','0','0',''
union all select 'DO','AC','','1','Valuta','@valuta','C','50','19','0','0',''
union all select 'DO','AC','SS','1','Cantitate','@cantitate','N','100','4','1','0',''
union all select 'DO','AC','SS','1','Cant. storno','@cantitate_storno','N','100','6','1','1',''
union all select 'DO','AC','SS','1','Cod','@cod','C','100','1','1','0',''
union all select 'DO','AC','SS','1','Denumire','@dencod','C','300','2','1','0',''
union all select 'DO','AC','SS','1','Gestiune','@dengestiune','C','150','3','1','0',''
union all select 'DO','AC','SS','1','Pret furnizor','@pvaluta','N','100','5','1','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AC','11','0','','Comanda','Comanda','@f_comanda','0','',''
union all select 'DO','AC','17','0','','Data facturii','de la','@f_datafacturiijos','1','pana la','@f_datafacturiisus'
union all select 'DO','AC','12','0','','Den. comanda','Denumire comanda','@f_dencomanda','0','',''
union all select 'DO','AC','10','0','','Den. cont','Denumire cont','@f_dencontvenituri','0','',''
union all select 'DO','AC','7','1','','Den.gestiune','Denumire gestiune','@f_dengestiune','0','',''
union all select 'DO','AC','9','0','','Den. gest. prim','Den. gestiune prim.','@f_dengestprim','0','',''
union all select 'DO','AC','14','1','','Den. loc munca','Denumire loc munca','@f_denlm','0','',''
union all select 'DO','AC','2','1','','Denumire tert','Denumire tert','@f_dentert','0','',''
union all select 'DO','AC','16','0','','Factura','Factura','@f_factura','0','',''
union all select 'DO','AC','6','0','','Gestiune','Gestiune','@f_gestiune','0','',''
union all select 'DO','AC','8','0','','Gest. prim.','Gestiune primitoare','@f_gestprim','0','',''
union all select 'DO','AC','13','0','','Loc munca','Loc munca','@f_lm','0','',''
union all select 'DO','AC','1','1','','Numar','Nr. document','@f_numar','0','',''
union all select 'DO','AC','3','0','','Tert','Tert','@f_tert','0','',''
union all select 'DO','AC','15','0','','Valoare','de la','@f_valoarejos','1','pana la','@f_valoaresus'

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AC','','8','Avize chitanta','','','','wIaDoc','','wStergDoc','wIaPozdoc','wScriuPozdoc','wStergPozdoc','1','','',''
union all select 'DO','AC','AC','1','Aviz','','','','','',' ',' ',' ',' ','1','','',''
union all select 'DO','AC','GC','90','Generare consumuri','Operatia realizeaza generarea consumurilor bazate pe reteta(tehnologia) produselor existente in AC. Articolele fara reteta nu vor fi luate in calcul. Consumurile generate vor avea aceleasi numere de document ca si documentele sursa, si se va fi din gestiunea proprietate (GESTCM) a documentelor sursa','','','','wOPGenerareCMDinVanzari','','','','','1','O','',''
union all select 'DO','AC','IB','60','Incasare factura','','','','','wOPIncasare','','','','','0','O','',''
union all select 'DO','AC','RN','80','Refacere inreg. cont','Operatie pentru refacere inregistrari contabile','','','','wOPRefacereInregistrariContabileDocument','','','','','1','O','wOPRefacereInregistrariContabile_p',''
union all select 'DO','AC','SD','1','Stornare factura','Operatie de generare document "stornat" din documentul selectat.Data doc sursa este data documentului de pe care se doreste stornarea. Data stornarii va fi data documentului stornat. In cazul stornarii AC trebui complectat clientul. In cazul AC-urilor fara factura la client se va alege TERTI DIVERSI.','text','','','wOPStornareDoc','','','','','1','O','wOPStornareDoc_p',''
union all select 'DO','AC','SS','20','Stornare Document','','','','','wOPStornareDocument','','','','','1','O','wOPStornareDocument_p',''
union all select 'DO','AC','ST','1','Definitivare','Operatie de definitivare a documentului de tip AP. Permite schimbarea in stare 2 a documentului selectat. Doar pentru avize in stare 2 se poate genera formular de factura','','','','wOPSchimbStare','','','','','1','O','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AC','','16','Categ. pret','AC','@categpret','@categpret','200','1','1','wACCategPret','','','','Categ. pret','','',''
union all select 'DO','AC','','6','Comanda','AC','@comanda','@dencomanda','300','0','1','wACComenzi','','','','Comanda','','',''
union all select 'DO','AC','','13','Cont coresp.','AC','@contcorespondent','','200','0','0','wACConturi','','','','Cont coresp.','','',''
union all select 'DO','AC','','12','Cont fact.','AC','@contfactura','','300','0','0','wACConturi','','','','Cont fact.','','',''
union all select 'DO','AC','','18','Contract','C','@contract','','300','0','0','','','','','Contract','','',''
union all select 'DO','AC','','5','Cont','AC','@contvenituri','@dencontvenituri','300','0','1','wACConturi','','','','Cont','','',''
union all select 'DO','AC','','2','Data','D','@data','','100','1','1','','','','','','','',''
union all select 'DO','AC','','25','Data expedierii','D','@dataexpedierii','','200','0','0','','','','','Data exp.','','',''
union all select 'DO','AC','','10','Data facturii','D','@datafacturii','','100','0','0','','','','','Data facturii','','',''
union all select 'DO','AC','','11','Data scadentei','D','@datascadentei','','100','0','0','','','','','Data scad.','','',''
union all select 'DO','AC','','22','Eliberat','C','@eliberat','','200','0','0','','','','','Eliberat','','',''
union all select 'DO','AC','','14','Explicatii','C','@explicatii','','300','0','0','','','','','Explicatii','','',''
union all select 'DO','AC','','6','Factura','AC','@factura','','200','0','1','wACFacturi','','','','factura','','',''
union all select 'DO','AC','','3','Gestiune','AC','@gestiune','@dengestiune','300','1','1','wACGestiuni','','','','Gestiune','','',''
union all select 'DO','AC','','9','Gest. prim.','AC','@gestprim','','300','0','0','wACGestiuni','','','','Gest. prim.','','',''
union all select 'DO','AC','','4','Agent','AC','@lm','@denlm','200','1','1','wACLocm','','','','Loc munca','','',''
union all select 'DO','AC','','23','Mijl.transp.','C','@mijloctp','','200','0','0','','','','','Mijl.transp.','','',''
union all select 'DO','AC','','24','Nr. mijl.transp.','C','@nrmijloctp','','200','0','0','','','','','Nr.mijl.transp.','','',''
union all select 'DO','AC','','1','Numar','C','@numar','','80','1','1','','','','','','','',''
union all select 'DO','AC','','21','Nr. buletin','C','@numarbuletin','','150','0','0','','','','','Nr. buletin','','',''
union all select 'DO','AC','','19','Nume delegat','C','@numedelegat','','300','0','0','','','','','Nume delegat','','',''
union all select 'DO','AC','','27','Observatii','C','@observatii','','200','0','0','','','','','Observatii','','',''
union all select 'DO','AC','','26','Ora expedierii','C','@oraexpedierii','','100','0','0','','','','','Ora exp.','','',''
union all select 'DO','AC','','15','Pct. livrare','AC','@punctlivrare','@denpunctlivrare','200','1','1','wACPuncteLivrare','','','','Pct. livrare','','',''
union all select 'DO','AC','','28','Pct. livrare exped.','C','@punctlivrareexped','','200','0','0','','','','','Pct.livr.exped','','',''
union all select 'DO','AC','','20','Seria buletin','C','@seriabuletin','','100','0','0','','','','','Seria buletin','','',''
union all select 'DO','AC','','5','Client','AC','@tert','@dentert','300','1','1','wACTerti','','','','Tert','','',''
union all select 'DO','AC','','17','Tva neex.','N','@tvaneexigibil','','200','0','0','','','','','Tva neex.','','',''
union all select 'DO','AC','','14','Val cu TVA','N','@valtotala',' ','100','1','0','','','','','Valoare cu TVA','','',''
union all select 'DO','AC','AC','33','Barcod','C','@barcod','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','2','Cantitate','N','@cantitate','','80','1','1','','','','','','','',''
union all select 'DO','AC','AC','18','Categ. pret','N','@categpret','','50','0','1','','','','','','','',''
union all select 'DO','AC','AC','1','Cod','AC','@cod','@denumire','300','1','1','wACNomenclator','','','','','','',''
union all select 'DO','AC','AC','10','Cod intrare','N','@codintrare','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','19','Comanda','C','@comanda','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','7','Cont coresp.','AC','@contcorespondent','','80','0','1','wACConturi','','','','','','',''
union all select 'DO','AC','AC','8','Cont factura','AC','@contfactura','','80','0','1','wACConturi','','','','','','',''
union all select 'DO','AC','AC','9','Cont intermed.','AC','@contintermediar','','80','0','1','wACConturi','','','','','','',''
union all select 'DO','AC','AC','20','Contract','C','@contract','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','21','Cont stoc','AC','@contstoc','','80','0','1','wACConturi','','','','','','',''
union all select 'DO','AC','AC','22','Cont venituri','AC','@contvenituri','','80','0','1','wACConturi','','','','','','',''
union all select 'DO','AC','AC','6','Cota Tva','N','@cotatva','','60','0','1','','','','','','','',''
union all select 'DO','AC','AC','16','Curs','C','@curs','','60','0','1','','','','','','','',''
union all select 'DO','AC','AC','23','Data expirarii','D','@dataexpirarii','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','32','Discount','N','@discount','','60','0','1','','','','','','','',''
union all select 'DO','AC','AC','24','DVI','C','@dvi','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','25','Explicatii','C','@explicatii','','150','0','1','','','','','','','',''
union all select 'DO','AC','AC','11','Factura','C','@factura','','100','0','1','','','','','','','',''
union all select 'DO','AC','AC','12','Gestiune','AC','@gestiune','','80','0','1','wACGestiuni','','','','','','',''
union all select 'DO','AC','AC','14','Gest.prim.','AC','@gestprim','','80','0','1','wACGestiuni','','','','','','',''
union all select 'DO','AC','AC','31','Jurnal','D','@jurnal','','60','0','1','','','','','','','',''
union all select 'DO','AC','AC','17','Loc munca','AC','@lm','','80','0','1','wACLocm','','','','','','',''
union all select 'DO','AC','AC','30','Locatie','C','@locatie','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','29','Lot','C','@lot','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','28','Nr. pozitie','N','@numarpozitie','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','13','Pret amanunt','N','@pamanunt','','80','1','1','','','','','','','',''
union all select 'DO','AC','AC','3','Pret stoc','N','@pstoc','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','27','Pct. livrare','C','@punctlivrare','','50','0','1','','','','','','','',''
union all select 'DO','AC','AC','5','Pret vanzare','N','@pvaluta','','80','1','1','','','','','','','',''
union all select 'DO','AC','AC','4','Suma Tva','N','@sumatva','','80','0','1','','','','','','','',''
union all select 'DO','AC','AC','26','Tva neex.','N','@tvaneexigibil','','60','0','1','','','','','','','',''
union all select 'DO','AC','AC','15','Valuta','C','@valuta','','40','0','1','','','','','','','',''
union all select 'DO','AC','GC','1','Data','D','@data','','200','1','1',' ','','','','','','',''
union all select 'DO','AC','IB','4','Numar chitanta','C','@chitanta','','250','0','1','','','','','','','',''
union all select 'DO','AC','IB','1','Cont casa','AC','@contcasa','@contcasa','200','0','1','wACConturi','','','','','','',''
union all select 'DO','AC','IB','2','Suma LEI','N','@sumalei','','200','0','1','','','','','','','',''
union all select 'DO','AC','IB','3','Suma valuta','N','@sumavaluta','','200','0','1','','','','','','','',''
union all select 'DO','AC','RN','3','Data','D','@data','','100','1','0','','','','','','','',''
union all select 'DO','AC','RN','2','Numar','C','@numar','','100','1','0','','','','','','','',''
union all select 'DO','AC','RN','1','Tip','C','@tip','','50','1','0','','','','','','','',''
union all select 'DO','AC','SD','5','Cantitate','N','@cantitate','','90','1','1','','','','','','','',''
union all select 'DO','AC','SD','4','Data stornarii','D','@datastorno','','100','1','1','','','','','','','',''
union all select 'DO','AC','SD','6','Gestiunea','AC','@gestiune','','250','0','1','wACGestiuni','','','','','','',''
union all select 'DO','AC','SD','5','Stornare factura','CHB','@plata_inc','','250','0','1','','','','','','','',''
union all select 'DO','AC','SD','1','Client','AC','@tert','@dentert','250','1','1','wACTerti','','','','','','',''
union all select 'DO','AC','SS','3','Data','D','@data','','100','1','0','','','','','','','',''
union all select 'DO','AC','SS','6','Data doc. storno','D','@datadoc','','100','1','1','','','','','','','',''
union all select 'DO','AC','SS','4','Tert','C','@dentert','','250','1','0','','','','','','','',''
union all select 'DO','AC','SS','7','Factura storno','C','@facturadoc','','100','1','1','','','','','','','',''
union all select 'DO','AC','SS','2','Numar','C','@numar',' ','100','1','0','','','','','','','',''
union all select 'DO','AC','SS','5','Numar doc. storno','C','@numardoc','','100','1','1','','','','','','','',''
union all select 'DO','AC','SS','1','Tip','C','@tip','','50','1','0','','','','','','','',''
union all select 'DO','AC','ST','1','Definitivare document','CHB','@definitivare','','130','1','1','','','','','Definitivare document','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'DO','AC','Avize chitanta','','PozDoc','DO','AC','','10','1'
union all select 'DO','AC','Note contabile','','PozDoc','IK','IC','','20','1'
GO
--Tab: Note contabile ---- PozDoc ,IK, IC
 if not exists (select 1 from webConfigTipuri t where exists (select 1 from webconfigmeniu w where w.meniu=t.meniu and w.TipMacheta='D') and meniu='IK' and tip='IC')
 begin

if exists (select 1 from webconfigmeniu where meniu='IK') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='IK'
delete from webconfigfiltre where meniu='IK' and ('IC'='' or isnull(tip,'')='IC')
delete from webconfiggrid where meniu='IK' and ('IC'='' or isnull(tip,'')='IC') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='IK' and ('IC'='' or isnull(tip,'')='IC') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='IK' and ('IC'='' or isnull(tip,'')='IC') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='IK' and ('IC'='' or isnull(TipSursa,'')='IC')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'IK','Inregistrari contabile','CONTABILITATE','','D',392.00,'','','<row><vechi><row id="392" nume="Inregistrari contabile" idparinte="999" tipmacheta="D" meniu="IK" publicabil="0"/></vechi></row>',0

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'IK','IC','','1','Cont credit','@contcreditor','C','70','30','1','0',''
union all select 'IK','IC','','1','Cont debit','@contdebitor','C','70','10','1','0',''
union all select 'IK','IC','','0','Data','@data','D','100','3','1','0',''
union all select 'IK','IC','','1','Data','@data','D','100','5','0','0',''
union all select 'IK','IC','','1','Comanda','@dencomanda','C','150','80','1','0',''
union all select 'IK','IC','','1','Den cont credit','@dencontcreditor','C','150','40','1','0',''
union all select 'IK','IC','','1','Den cont debit','@dencontdebitor','C','150','20','1','0',''
union all select 'IK','IC','','1','Loc de munca','@denlm','C','150','70','1','0',''
union all select 'IK','IC','','1','Explicatii','@explicatii','C','200','60','1','0',''
union all select 'IK','IC','','0','Numar document','@nrdocument','C','100','2','1','0',''
union all select 'IK','IC','','0','Pozitii','@nrpozitii','N','80','4','1','0',''
union all select 'IK','IC','','1','Suma','@suma','N','100','50','1','0',''
union all select 'IK','IC','','0','Tip document','@tipdocument','C','60','1','1','0',''
union all select 'IK','IC','','1','Tip document','@tipdocument','C','100','3','0','0',''

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'IK','IC','2','1','','Numar document','Numar document','@f_nrdocument','0','',''
union all select 'IK','IC','1','1','','Tip document','Tip document','@f_tipdocument','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'IK','IC','','1','Inreg contabile','','','','wIaIncon','','','wIaPozIncon','','','1',' ','',''
union all select 'IK','IC','IC','1','Test','','','','','wOPTest','','','','','1','O','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'IK','IC','','30','Data','D','@data','','100','1','0','','','','','','','',''
union all select 'IK','IC','','20','Numar doc.','C','@nrdocument','','100','1','0','','','','','Document','','',''
union all select 'IK','IC','','10','Tip document','C','@tipdocument','','50','1','0','','','','','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
 end
