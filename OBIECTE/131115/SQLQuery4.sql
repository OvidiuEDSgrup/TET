
--delete from webconfiggrid where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('AP'='' or isnull(subtip,'')='AP')
--delete from webconfigtipuri where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('AP'='' or isnull(subtip,'')='AP')
--delete from webconfigform where meniu='DO' and ('AP'='' or isnull(tip,'')='AP') and ('AP'='' or isnull(subtip,'')='AP')
--delete from webConfigTaburi where MeniuSursa='DO' and ('AP'='' or isnull(TipSursa,'')='AP')


insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AP','DA','1','Discount avans','','','','','','',' ',' ',' ','1','A','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'DO','AP','DA','133','Barcod','C','@barcod','','80','0','1','','','','','','','',''
union all select 'DO','AP','DA','3','Cantitate','N','@cantitate','','80','1','1','','','','','','','',''
union all select 'DO','AP','DA','18','Categ. pret','N','@categpret','','50','0','1','','','','','','','',''
union all select 'DO','AP','DA','1','Cod','AC','@cod','@denumire','700','1','1','wACNomenclator','','','','','','',''
union all select 'DO','AP','DA','2','Cod fara stoc','CHB','@codfarastoc','','150','1','1','','','','','','','',''
union all select 'DO','AP','DA','7','Cod intrare','AC','@codintrare','@dencodintrare','100','1','1','wACCodIntrare','','','','','','',''
union all select 'DO','AP','DA','19','Comanda','C','@comanda','','80','0','1','','','','','','','',''
union all select 'DO','AP','DA','7','Cont coresp.','AC','@contcorespondent','@contcorespondent','80','0','0','wACConturi','','','','','','',''
union all select 'DO','AP','DA','8','Cont factura','AC','@contfactura','@contfactura','80','0','0','wACConturi','','','','','','',''
union all select 'DO','AP','DA','9','Cont intermed.','AC','@contintermediar','@contintermediar','80','0','1','wACConturi','','','','','','',''
union all select 'DO','AP','DA','20','Contract','C','@contract','','80','0','1','','','','','','','',''
union all select 'DO','AP','DA','21','Cont stoc','AC','@contstoc','@contstoc','80','0','1','wACConturi','','','','','','',''
union all select 'DO','AP','DA','22','Cont venituri','AC','@contvenituri','@contvenituri','80','0','1','wACConturi','','','','','','',''
union all select 'DO','AP','DA','5','Cota Tva','N','@cotatva','','60','0','0','','','','','','','',''
union all select 'DO','AP','DA','16','Curs','C','@curs','','60','0','1','','','','','','','',''
union all select 'DO','AP','DA','23','Data expirarii','D','@dataexpirarii','','80','0','1','','','','','','','',''
union all select 'DO','AP','DA','150','Val cu TVA','N','@detalii_valtotala','','100','0','0','','','','','','','','Math.round((Number(row.@pvanzare)*Number(row.@cantitate))+Number(row.@sumatva))'
union all select 'DO','AP','DA','5','Disc proc (%)','N','@discount','','40','1','1','','','','','Disc proc (%)','','',''
union all select 'DO','AP','DA','33','Disc suma','N','@discsuma','','80','0','0','','','','',' ','','',''
union all select 'DO','AP','DA','24','DVI','C','@dvi','','80','0','1','','','','','','','',''
union all select 'DO','AP','DA','6','Explicatii','C','@explicatii','','150','1','1','','','','','','','',''
union all select 'DO','AP','DA','11','Factura','C','@factura','','100','0','1','','','','','','','',''
union all select 'DO','AP','DA','12','Gestiune','AC','@gestiune','@gestiune','80','0','1','wACGestiuni','','','','','','',''
union all select 'DO','AP','DA','14','Gest.prim.','AC','@gestprim','@gestprim','80','0','1','wACGestiuni','','','','','','',''
union all select 'DO','AP','DA','31','Jurnal','D','@jurnal','','60','0','1','','','','','','','',''
union all select 'DO','AP','DA','17','Loc munca','AC','@lm','@denlm','80','0','1','wACLocm','','','','','','',''
union all select 'DO','AP','DA','30','Locatie','C','@locatie','','80','0','1','','','','','','','',''
union all select 'DO','AP','DA','29','Lot','C','@lot','','80','0','1','','','','','','','',''
union all select 'DO','AP','DA','28','Nr. pozitie','N','@numarpozitie','','80','0','1','','','','','','','',''
union all select 'DO','AP','DA','13','Pret amanunt','N','@pamanunt','','80','0','1','','','','','','','',''
union all select 'DO','AP','DA','3','Pret stoc','N','@pstoc','','80','0','0','','','','','','','',''
union all select 'DO','AP','DA','27','Pct. livrare','C','@punctlivrare','','50','0','1','','','','','','','',''
union all select 'DO','AP','DA','4','Pret f tva','N','@pvaluta','','80','1','0','','','','','','','',''
union all select 'DO','AP','DA','6','Suma Tva','N','@sumatva','','80','0','0','','','','','','','',''
union all select 'DO','AP','DA','26','Tva neex.','N','@tvaneexigibil','','60','0','1','','','','','','','',''
union all select 'DO','AP','DA','15','Valuta','C','@valuta','','40','0','1','','','','','','','',''