
if exists (select 1 from webconfigmeniu where meniu='YSO_CO') begin raiserror('Acest meniu este configurat deja! Daca doriti, stergeti manual linia din webConfigMeniu',11,1) return end
--delete from webconfigmeniu where tipMacheta='D' and meniu='YSO_CO'
delete from webconfigfiltre where meniu='YSO_CO' and (''='' or isnull(tip,'')='')
delete from webconfiggrid where meniu='YSO_CO' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigtipuri where meniu='YSO_CO' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webconfigform where meniu='YSO_CO' and (''='' or isnull(tip,'')='') and (''='' or isnull(subtip,'')='')
delete from webConfigTaburi where MeniuSursa='YSO_CO' and (''='' or isnull(TipSursa,'')='')

insert into webconfigmeniu --(id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul)
				(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'YSO_CO','Cereri oferta','CONTRACTE','contracte','D',1000.00,' ',' ',null,1

insert into webconfiggrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, Formula) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null
union all select 'YSO_CO','OB','','0','Explicatii','@explicatii','C','150','20','1','0',' '
union all select 'YSO_CO','OB','','1','Cant.','@cantitate','N','40','5','1','0',''
union all select 'YSO_CO','OB','','1','Cod','@cod','C','100','2','1','0',''
union all select 'YSO_CO','OB',' ','1','Cod specific','@codspecific','C','100','1','0','0',''
union all select 'YSO_CO','OB','','1','Cota tva','@cotatva','N','50','13','1','0',''
union all select 'YSO_CO','OB','','0','Curs','@curs','N','30','13','0','0',''
union all select 'YSO_CO','OB',' ','0','Data','@data','D','80','2','1','0',''
union all select 'YSO_CO','OB','','0','Denumire gestiune','@dengestiune','C','80','7','1','0',''
union all select 'YSO_CO','OB','','0','Denumire gest.prim.','@dengestiune_primitoare','C','80','9','0','0',''
union all select 'YSO_CO','OB','','0','Denumire loc de munca','@denlm','C','80','11','0','0',''
union all select 'YSO_CO','OB','','1','Periodicitate','@denperiodicitate','C','100','17','0','0',''
union all select 'YSO_CO','OB','','0','Stare','@denstare','C','50','16','0','0',''
union all select 'YSO_CO','OB','','0','Stare','@denstare','C','50','17','1','0',''
union all select 'YSO_CO','OB','','0','Denumire tert','@dentert','C','150','4','1','0',''
union all select 'YSO_CO','OB','','1','Denumire','@denumire','C','200','3','1','0',''
union all select 'YSO_CO','OB','','1','Discount','@discount','N','50','15','1','0',''
union all select 'YSO_CO','OB','','1','Explicatii','@explicatii','C','150','19','1','0',''
union all select 'YSO_CO','OB','','0','Gestiune','@gestiune','C','30','6','0','0',''
union all select 'YSO_CO','OB','','0','Gestiune primitoare','@gestiune_primitoare','C','30','8','0','0',''
union all select 'YSO_CO','OB','','0','Loc de munca','@lm','C','30','10','0','0',''
union all select 'YSO_CO','OB','','0','Numar','@numar','C','100','1','1','0',''
union all select 'YSO_CO','OB','','0','Pozitii','@pozitii','N','30','18','1','0',''
union all select 'YSO_CO','OB','','1','Pret','@pret','N','50','11','1','0',''
union all select 'YSO_CO','OB','','0','Punct livrare','@punct_livrare','C','50','5','0','0',''
union all select 'YSO_CO','OB','','1','Termen','@termen','D','100','4','0','0',''
union all select 'YSO_CO','OB','','0','Tert','@tert','C','50','3','0','0',''
union all select 'YSO_CO','OB','','1','UM','@um','C','30','6','1','0',''
union all select 'YSO_CO','OB','','0','Valabilitate','@valabilitate','D','80','14','0','0',''
union all select 'YSO_CO','OB','','0','Valoare','@valoare','N','50','15','1','0',''
union all select 'YSO_CO','OB','','0','Valuta','@valuta','C','30','12','0','0',''
union all select 'YSO_CO','OB','GL','1','Cantitate','@cantitate','N','80','3','1','1',''
union all select 'YSO_CO','OB','GL','1','Cod','@cod','C','70','1','1','0',''
union all select 'YSO_CO','OB','GL','1','De facturat','@defacturat','N','100','7','0','1',''
union all select 'YSO_CO','OB','GL','1','Denumire','@denumire','C','200','2','1','0',''
union all select 'YSO_CO','OB','GL','1','Facturat','@facturat','N','80','6','0','0',''
union all select 'YSO_CO','OB','GL','1','Rezervat','@rezervat','N','80','5','0','0',''
union all select 'YSO_CO','OB','GL','1','Stoc in gest.','@stoc','N','80','4','0','0',''
union all select 'YSO_CO','OB','','1','Cant.2','@detalii__cantitate2','N','40','7','1','0',' '
union all select 'YSO_CO','OB','','1','UM2','@detalii_UM2','C','30','9','1','0',' '
union all select 'YSO_CO','OB','GR','1','UM','@UM','N','30','4','1','0',' '
union all select 'YSO_CO','OB','GL','1','UM','@UM','C','80','4','1','0',' '

insert into webconfigFiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) 
select top 0 null,null,null,null,null,null,null,null,null,null,null
union all select 'YSO_CO','OB','3','0','','Denumire gest.','Denumire gestiune','@f_dengestiune','0','',''
union all select 'YSO_CO','OB','5','0','','Denumire gest.prim.','Denumire gest. prim.','@f_dengestiune_primitoare','0','',''
union all select 'YSO_CO','OB','9','0','','Denumire loc de munca','Denumire loc munca','@f_denlm','0','',''
union all select 'YSO_CO','OB','6','1','','Denumire tert','Denumire tert','@f_dentert','0','',''
union all select 'YSO_CO','OB','2','1','','Gestiune','Gestiune','@f_gestiune','0','',''
union all select 'YSO_CO','OB','4','0','','Gestiune primitoare','Gestiune primitoare','@f_gestiune_primitoare','0','',''
union all select 'YSO_CO','OB','8','0','','Loc de munca','Loc de munca','@f_lm','0','',''
union all select 'YSO_CO','OB','1','1','','Numar','Numar comanda','@f_numar','0','',''
union all select 'YSO_CO','OB','10','1','','Stare','Stare contract','@f_stare','0','',''

insert into webconfigTipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare,tasta) 
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'YSO_CO','OB','','0','Oferta beneficiar','','','','wIaContracte','','wStergContracte','wIaPozContracteSP','wScriuPozContracte','wStergPozContracte','1',' ','',''
union all select 'YSO_CO','OB','GL','11','Generare Oferta Pret','Operatia genereaza o comanda de livrare cu pozitiile aferente si cantitatile modificabile din coloana "Cantitate"','','','','yso_wOPGenerareComandaLivrare','','','','','1','O','yso_wOPGenerareComandaLivrare_p',''
union all select 'YSO_CO','OB','OB','1','Pozitie oferta in UM1','','','','','','','','','','1',' ','',''
union all select 'YSO_CO','OB','U2','2','Pozitie oferta in UM2','','','','','','','','','','1',' ','',''

insert into webconfigForm (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula)
select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
union all select 'YSO_CO','OB','OB','13','Observatii','T','@detalii_observatii','','800','1','1','','','','','','','',''
union all select 'YSO_CO','OB','GL','3','Aviz nefacturat','CHB','@aviznefacturat','','200','0','1','','','','','','','',''
union all select 'YSO_CO','OB','GL','1','Data comanda','D','@data','','200','1','1','','','','','','','',''
union all select 'YSO_CO','OB','GL','17','Eliberat','C','@eliberat','','200','0','1','','','','','','','',''
union all select 'YSO_CO','OB','GL','13','Mijloc transp.','C','@mijloctransport','','200','0','1','','','','','','','',''
union all select 'YSO_CO','OB','GL','14','Numar mij.transp.','C','@nrmijloctransport','','200','0','1','','','','','','','',''
union all select 'YSO_CO','OB','GL','16','Numar buletin','C','@numarbuletin','','100','0','1','','','','','','','',''
union all select 'YSO_CO','OB','GL','12','Delegat','C','@numedelegat','','200','0','1','','','','','','','',''
union all select 'YSO_CO','OB','GL','8','Observatii','C','@observatii','','200','0','1','','','','','','','',''
union all select 'YSO_CO','OB','GL','15','Seria buletin','C','@seriabuletin','','100','0','1','','','','','','','',''
union all select 'YSO_CO','OB','','25','Stare','AC','@stare','@denstare','100','1','0','','','','','','','',''
union all select 'YSO_CO','OB','','10','Curs','N','@curs','','50','0','1','','','','','','','',''
union all select 'YSO_CO','OB','','2','Data','D','@data',' ','100','1','1','','','','','','','',''
union all select 'YSO_CO','OB','','12','Responsabil','C','@detalii_responsabil','','150','1','1','','','','','Persoana','','',''
union all select 'YSO_CO','OB','','11','Explicatii','T','@explicatii','','800','0','1','','','','','','','',''
union all select 'YSO_CO','OB','','3','Gestiune','AC','@gestiune','@dengestiune','200','1','1','wACGestiuni','','','','Gestiune','','',''
union all select 'YSO_CO','OB','','8','Gestiune primitoare','AC','@gestiune_primitoare','@dengestiune_primitoare','200','1','1','wACGestiuni','','','','Gestiune primitoare','','',''
union all select 'YSO_CO','OB','','20','Cerere coresp.','AC','@idContractCorespondent','@denidContractCorespondent','250','1','1','wACContracteBeneficiar','','','','Contractul corespondent...','','',''
union all select 'YSO_CO','OB','','7','Loc de munca','AC','@lm','@denlm','200','1','1','wACLocm','','','','Loc de munca','','',''
union all select 'YSO_CO','OB','','1','Numar','C','@numar',' ','100','1','1','','','','','','','',''
union all select 'YSO_CO','OB','','5','Punct livrare','AC','@punct_livrare','@denpunct_livrare','200','1','1','wACPuncteLivrare','','','','Punct livrare','','',''
union all select 'YSO_CO','OB','','4','Tert','AC','@tert','@dentert','200','1','1','wACTerti','','','','Tert','','',''
union all select 'YSO_CO','OB','','6','Valabilitate','D','@valabilitate',' ','100','0','1','','','','','','','',''
union all select 'YSO_CO','OB','','9','Valuta','AC','@valuta','@denvaluta','200','0','1','wACValuta','','','','Valuta','','',''
union all select 'YSO_CO','OB','OB','2','Cantitate','N','@cantitate',' ','50','1','1','','','','','','','',''
union all select 'YSO_CO','OB','OB','1','Cod','AC','@cod','@dencod','350','1','1','wACNomenclator','','','','Articol','','',''
union all select 'YSO_CO','OB','OB','1','Cod specific','AC','@codspecific','@dencodspecific','200','0','1','wACNomSpecif','','','','Articol specific','','',''
union all select 'YSO_CO','OB','OB','4','Discount','N','@discount',' ','50','0','1','','','','','','','',''
union all select 'YSO_CO','OB','OB','7','Explicatii','C','@explicatii','','800','1','1','','','','','','','',''
union all select 'YSO_CO','OB','OB','6','Periodicitate','CB','@periodicitate','','120','0','1','','0,1,2,3,4,6,12','Fara periodicitate,Lunar,2 luni,Trimestrial,4 luni,Semestrial,Anual','0','','','',''
union all select 'YSO_CO','OB','OB','3','Pret','N','@pret',' ','50','1','1','','','','','','','',''
union all select 'YSO_CO','OB','OB','5','Termen','D','@termen',' ','100','0','1','','','','','','','',''
union all select 'YSO_CO','OB','U2','2','Cantitate UM2','N','@detalii__cantitate2',' ','50','1','1','','','','','','','',''
union all select 'YSO_CO','OB','U2','1','Cod','AC','@cod','@dencod','350','1','1','wACNomenclator','','','','Articol','','',''
union all select 'YSO_CO','OB','U2','1','Cod specific','AC','@codspecific','@dencodspecific','200','0','1','wACNomSpecif','','','','Articol specific','','',''
union all select 'YSO_CO','OB','U2','4','Discount','N','@discount',' ','50','0','1','','','','','','','',''
union all select 'YSO_CO','OB','U2','7','Explicatii','C','@explicatii','','800','1','1','','','','','','','',''
union all select 'YSO_CO','OB','U2','0','Poz.cerere.coresp','AC','@idPozContractCoresp','@denidPozContractCoresp','250','0','1','yso_wACPozContracteNoi','','','','','','',''
union all select 'YSO_CO','OB','U2','6','Periodicitate','CB','@periodicitate','','120','0','1','','0,1,2,3,4,6,12','Fara periodicitate,Lunar,2 luni,Trimestrial,4 luni,Semestrial,Anual','0','','','',''
union all select 'YSO_CO','OB','U2','3','Pret','N','@pret',' ','50','1','1','','','','','','','',''
union all select 'YSO_CO','OB','U2','5','Termen','D','@termen',' ','100','0','1','','','','','','','',''
union all select 'YSO_CO','OB','U2','13','Observatii','T','@detalii__observatii','','800','1','1','','','','','','','',''

insert into webconfigtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)
select top 0 null,null,null,null,null,null,null,null,null,null
union all select 'YSO_CO','OB','Comenzi livrare','','D','D_CL','CL','wIaContracte_p','9','1'
union all select 'YSO_CO','OB','Documente cerere','','C','RA','RA','','3','1'
union all select 'YSO_CO','OB','Fisiere cerere','','C','FF','FF','','4','1'
union all select 'YSO_CO','OB','Jurnal cerere','','D','JB','JB','','2','1'
union all select 'YSO_CO','OB','Oferta beneficiar','','PozDoc','YSO_CO','OB','','1','1'
GO