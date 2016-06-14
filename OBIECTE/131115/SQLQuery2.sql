
--delete from webconfiggrid where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('BK'='' or isnull(subtip,'')='BK')
--delete from webconfigtipuri where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('BK'='' or isnull(subtip,'')='BK')
--delete from webconfigform where meniu='CO' and ('BK'='' or isnull(tip,'')='BK') and ('BK'='' or isnull(subtip,'')='BK')
--delete from webConfigTaburi where MeniuSursa='CO' and ('BK'='' or isnull(TipSursa,'')='BK')


insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','BK','DA','1','Discount avans','','','','','','','','','','1','','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'CO','BK','DA','3','Cantitate','N','@cantitate','','150','1','1','','','','','Cantitate','','',''
union all select 'CO','BK','DA','6','Cantitate','N','@cantitateum1','','150','0','1','','','','','Cantitate UM1','','',''
union all select 'CO','BK','DA','7','Cantitate um2','N','@cantitateum2','','150','0','1','','','','','Cantitate UM2','','',''
union all select 'CO','BK','DA','8','Cantitate UM3','N','@cantitateum3','','150','0','1','','','','','Cantitate UM3','','',''
union all select 'CO','BK','DA','10','Categ. pret','AC','@categpret','@categpret','50','0','1','wACCategPret','','','','Categorie pret','','',''
union all select 'CO','BK','DA','1','Cod','AC','@cod','@denumire','600','1','1','wACNomenclator','','','','Cod','','',''
union all select 'CO','BK','DA','2','Cod fara stoc','CHB','@codfarastoc','','120','1','1','','','','','Cod fara stoc','','',''
union all select 'CO','BK','DA','13','Cota tva','N','@cotatva','','60','0','1','','','','','Cota tva','','',''
union all select 'CO','BK','DA','11','Curs','C','@curs','','50','0','1','','','','','Curs','','',''
union all select 'CO','BK','DA','16','Data exp.','D','@dataexpirarii','','100','0','1','','','','','Data expirarii','','',''
union all select 'CO','BK','DA','12','Discount','C','@discount','','100','1','1','','','','','Discount','','',''
union all select 'CO','BK','DA','20','Explicatii','N','@explicatii','','250','1','1','','','','','Explicatii','','',''
union all select 'CO','BK','DA','2','Gestiune','AC','@gestiune','@gestiune','150','0','1','wACGestiuni','','','','Gestiune','','',''
union all select 'CO','BK','DA','14','Disc.supl.2','N','@info1','','100','0','1','','','','','Info1','','',''
union all select 'CO','BK','DA','27','Info10','N','@info10','','150','0','1','','','','','Info10','','',''
union all select 'CO','BK','DA','28','Info11','N','@info11','','150','0','1','','','','','Info11','','',''
union all select 'CO','BK','DA','29','Info12','C','@info12','','200','0','1','','','','','Info12','','',''
union all select 'CO','BK','DA','30','Info13','C','@info13','','200','0','1','','','','','Info13','','',''
union all select 'CO','BK','DA','31','Info14','C','@info14','','200','0','1','','','','','Info14','','',''
union all select 'CO','BK','DA','32','Info15','C','@info15','','200','0','1','','','','','Info15','','',''
union all select 'CO','BK','DA','33','Info16','C','@info16','','200','0','1','','','','','Info16','','',''
union all select 'CO','BK','DA','34','Info17','C','@info17','','200','0','1','','','','','Info17','','',''
union all select 'CO','BK','DA','19','Info2','C','@info2','','250','0','1','','','','','Info2','','',''
union all select 'CO','BK','DA','18','Disc.supl.3','N','@info3','','100','0','1','','','','','Info3','','',''
union all select 'CO','BK','DA','21','Info4','C','@info4','','250','0','1','','','','','Info4','','',''
union all select 'CO','BK','DA','22','Info5','C','@info5','','250','0','1','','','','','Info5','','',''
union all select 'CO','BK','DA','23','Info6','D','@info6','','100','0','1','','','','','Info6','','',''
union all select 'CO','BK','DA','24','Info7','D','@info7','','100','0','1','','','','','Info7','','',''
union all select 'CO','BK','DA','25','Info8','N','@info8','','150','0','1','','','','','Info8','','',''
union all select 'CO','BK','DA','26','Info9','N','@info9','','150','0','1','','','','','Info9','','',''
union all select 'CO','BK','DA','15','Lot','C','@lot','','150','0','1','','','','','Lot','','',''
union all select 'CO','BK','DA','0','Mod plata','C','@modplata',' ','100','0','1',' ','','','','Selectati','','',''
union all select 'CO','BK','DA','35','Nr. pozitie','N','@numarpozitie','','150','0','1','','','','','Nr. pozitie','','',''
union all select 'CO','BK','DA','17','Obiect','C','@obiect','','150','0','1','','','','','Obiect','','',''
union all select 'CO','BK','DA','9','Pret  f Tva','N','@pret','','200','1','0','','','','','Pret','','',''
union all select 'CO','BK','DA','4','Termen1','N','@Tcantitate','','150','0','1','','','','','Termen1','','',''
union all select 'CO','BK','DA','5','Termen2','N','@Tpret','','100','0','1','','','','','Termen2','','',''