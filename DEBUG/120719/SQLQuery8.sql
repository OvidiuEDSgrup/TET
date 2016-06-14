select * from docsters d where d.Tert like  'RO15936519'

select * 
-- update p set val_logica=0
from par p where p.Parametru='BLOCSOLD'

--insert pozdoc
select top 100 Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil
,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator
,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert
,Factura,Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama
,Accize_cumparare,Accize_datorate,Contract,Jurnal,null as detalii
--into pozdoctmp
from sysspd s 
where 
--s.Numar='118703' and s.Cod in ('200-180214','100-200216')
not exists (select 1 from pozdoc p where p.Subunitate=s.Subunitate and p.Tip=s.Tip and p.Numar=s.Numar
and p.Data=s.Data and p.Numar_pozitie=s.Numar_pozitie)
order by s.Data_stergerii desc

select * 
-- update p set val_logica=1
from par p where p.Parametru='BLOCSOLD'

select * from pozdoc p where p.Numar='118703' 
select * from pozdoctmp s 
where exists
(select 1 from pozdoc p where p.Subunitate=s.Subunitate and p.Tip=s.Tip and p.Numar=s.Numar
and p.Data=s.Data and p.Numar_pozitie=s.Numar_pozitie)