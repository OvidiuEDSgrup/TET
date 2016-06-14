--select * from sysspd s where s.Numar='4555' order by s.Data_stergerii desc
-- insert pozdoc
select Subunitate',' Tip',' Numar',' Cod',' Data',' Gestiune',' Cantitate',' Pret_valuta',' Pret_de_stoc',' Adaos',' Pret_vanzare',' Pret_cu_amanuntul
',' TVA_deductibil',' Cota_TVA',' Utilizator',' Data_operarii',' Ora_operarii',' Cod_intrare',' Cont_de_stoc',' Cont_corespondent',' TVA_neexigibil
',' Pret_amanunt_predator',' Tip_miscare',' Locatie',' Data_expirarii',' Numar_pozitie',' Loc_de_munca',' Comanda',' Barcod',' Cont_intermediar
',' Cont_venituri',' Discount',' Tert',' Factura',' Gestiune_primitoare',' Numar_DVI',' Stare',' Grupa',' Cont_factura',' Valuta',' Curs',' Data_facturii
',' Data_scadentei',' Procent_vama',' Suprataxe_vama',' Accize_cumparare',' Accize_datorate',' Contract',' Jurnal',' null 
from sysspd s where s.Data_stergerii='2012-05-24 16:14:15.257' and s.Gestiune='101'
and not exists 
(select 1 from pozdoc p where p.Subunitate=s.subunitate and p.Tip=s.Tip and p.Numar=s.Numar and p.Data=s.Data 
	and p.Numar_pozitie=s.Numar_pozitie)
	
select * 
-- delete p
from pozdoc p
where p.Gestiune<>'101'
and exists
(select 1 from sysspd s where s.Data_stergerii='2012-05-24 16:14:15.257' and p.Subunitate=s.subunitate and p.Tip=s.Tip and p.Numar=s.Numar and p.Data=s.Data 
	and p.Numar_pozitie=s.Numar_pozitie)
	
select *
--Subunitate',' Tip',' Numar',' Cod',' Data',' Gestiune',' Cantitate',' Pret_valuta',' Pret_de_stoc',' Adaos',' Pret_vanzare',' Pret_cu_amanuntul
--',' TVA_deductibil',' Cota_TVA',' Utilizator',' Data_operarii',' Ora_operarii',' Cod_intrare',' Cont_de_stoc',' Cont_corespondent',' TVA_neexigibil
--',' Pret_amanunt_predator',' Tip_miscare',' Locatie',' Data_expirarii',' Numar_pozitie',' Loc_de_munca',' Comanda',' Barcod',' Cont_intermediar
--',' Cont_venituri',' Discount',' Tert',' Factura',' Gestiune_primitoare',' Numar_DVI',' Stare',' Grupa',' Cont_factura',' Valuta',' Curs',' Data_facturii
--',' Data_scadentei',' Procent_vama',' Suprataxe_vama',' Accize_cumparare',' Accize_datorate',' Contract',' Jurnal',' null 
from sysspd s where 
s.Numar in 
('4510','4518','4521','4532','4533','4536','4597','4602','4617','4642','4643','4680','4697','4699','4704','1709','4711','4761','4778','4780')
--s.Data_stergerii='2012-05-08 14:56:31.300' --and s.Gestiune='101'
order by s.Data_stergerii desc

select *
--Subunitate',' Tip',' Numar',' Cod',' Data',' Gestiune',' Cantitate',' Pret_valuta',' Pret_de_stoc',' Adaos',' Pret_vanzare',' Pret_cu_amanuntul
--',' TVA_deductibil',' Cota_TVA',' Utilizator',' Data_operarii',' Ora_operarii',' Cod_intrare',' Cont_de_stoc',' Cont_corespondent',' TVA_neexigibil
--',' Pret_amanunt_predator',' Tip_miscare',' Locatie',' Data_expirarii',' Numar_pozitie',' Loc_de_munca',' Comanda',' Barcod',' Cont_intermediar
--',' Cont_venituri',' Discount',' Tert',' Factura',' Gestiune_primitoare',' Numar_DVI',' Stare',' Grupa',' Cont_factura',' Valuta',' Curs',' Data_facturii
--',' Data_scadentei',' Procent_vama',' Suprataxe_vama',' Accize_cumparare',' Accize_datorate',' Contract',' Jurnal',' null 
from test1..pozdoc s where s.Numar in 
('4510','4518','4521','4532','4533','4536','4597','4602','4617','4642','4643','4680','4697','4699','4704','1709','4711','4761','4778','4780')
--s.Data_stergerii='2012-05-24 16:14:15.257' and s.Gestiune='101'
--order by s.Data_stergerii desc

select * from sysspcon

select distinct numar
--Subunitate',' Tip',' Numar',' Cod',' Data',' Gestiune',' Cantitate',' Pret_valuta',' Pret_de_stoc',' Adaos',' Pret_vanzare',' Pret_cu_amanuntul
--',' TVA_deductibil',' Cota_TVA',' Utilizator',' Data_operarii',' Ora_operarii',' Cod_intrare',' Cont_de_stoc',' Cont_corespondent',' TVA_neexigibil
--',' Pret_amanunt_predator',' Tip_miscare',' Locatie',' Data_expirarii',' Numar_pozitie',' Loc_de_munca',' Comanda',' Barcod',' Cont_intermediar
--',' Cont_venituri',' Discount',' Tert',' Factura',' Gestiune_primitoare',' Numar_DVI',' Stare',' Grupa',' Cont_factura',' Valuta',' Curs',' Data_facturii
--',' Data_scadentei',' Procent_vama',' Suprataxe_vama',' Accize_cumparare',' Accize_datorate',' Contract',' Jurnal',' null 
from pozdoc s where 
s.Numar in 
('4510','4518','4521','4532','4533','4536','4597','4602','4617','4642','4643','4680','4697','4699','4704','1709','4711','4761','4778','4780')
--s.Data_stergerii='2012-05-08 14:56:31.300' --and s.Gestiune='101'
--order by s.Data_stergerii desc