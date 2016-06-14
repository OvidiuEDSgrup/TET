--select * from yso_DetTabInl d where d.Tip<0 and d.Camp_Magic like 'bp'
--select * from yso_TabInl t where t.Tip<0 and t.Denumire_SQL='bp'

select * --delete t
from tet..bp t where exists 
--insert test..bp (Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,Client,Cod_citit_de_la_tastatura,CodPLU,Cod_produs,Categorie,UM,Cantitate,Cota_TVA,Tva,Pret,Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului,Loc_de_munca,Discount,IdAntetBon,lm_real,Comanda_asis,Contract)
(select --s.*,
b.Casa_de_marcat,b.Factura_chitanta,b.Numar_bon,b.Numar_linie,b.Data,b.Ora,b.Tip,b.Vinzator,b.Client,b.Cod_citit_de_la_tastatura,b.CodPLU,b.Cod_produs,b.Categorie,b.UM,b.Cantitate,b.Cota_TVA,b.Tva,b.Pret,b.Total,b.Retur,b.Inregistrare_valida,b.Operat,b.Numar_document_incasare,b.Data_documentului,b.Loc_de_munca,b.Discount,b.IdAntetBon,b.lm_real,b.Comanda_asis,b.Contract 
-- delete b
from tet2012..bp b 
--outer apply 
--(select top 1 * from yso_syssbp s
--where b.Data=s.Data and b.Casa_de_marcat=s.Casa_de_marcat and b.Vinzator=s.Vinzator and b.Numar_bon=s.Numar_bon and b.Numar_linie=s.Numar_linie
--order by s.data_stergerii desc) s
where not exists 
(select 1 from test1..bp p 
where b.Data=p.Data and b.Casa_de_marcat=p.Casa_de_marcat and b.Vinzator=p.Vinzator and b.Numar_bon=p.Numar_bon and b.Numar_linie=p.Numar_linie)
and b.Data=t.Data and b.Casa_de_marcat=t.Casa_de_marcat and b.Vinzator=t.Vinzator and b.Numar_bon=t.Numar_bon and b.Numar_linie=t.Numar_linie)



select * --delete t
from tet..pozdoc t where exists (
--insert test..pozdoc (Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,Contract,Jurnal,detalii)
select --s.*,
p.Subunitate,p.Tip,p.Numar,p.Cod,p.Data,p.Gestiune,p.Cantitate,p.Pret_valuta,p.Pret_de_stoc,p.Adaos,p.Pret_vanzare,p.Pret_cu_amanuntul,p.TVA_deductibil,p.Cota_TVA,p.Utilizator,p.Data_operarii,p.Ora_operarii,p.Cod_intrare,p.Cont_de_stoc,p.Cont_corespondent,p.TVA_neexigibil,p.Pret_amanunt_predator,p.Tip_miscare,p.Locatie,p.Data_expirarii,p.Numar_pozitie,p.Loc_de_munca,p.Comanda,p.Barcod,p.Cont_intermediar,p.Cont_venituri,p.Discount,p.Tert,p.Factura,p.Gestiune_primitoare,p.Numar_DVI,p.Stare,p.Grupa,p.Cont_factura,p.Valuta,p.Curs,p.Data_facturii,p.Data_scadentei,p.Procent_vama,p.Suprataxe_vama,p.Accize_cumparare,p.Accize_datorate,p.Contract,p.Jurnal,p.detalii 
-- delete p
from tet2012..pozdoc p 
--outer apply 
--(select top 1 * from sysspd s 
--where p.Subunitate=s.Subunitate and p.Tip=s.tip and p.Numar=s.Numar and p.Data=s.Data and p.Numar_pozitie=s.Numar_pozitie
--order by s.data_stergerii desc) s
where not exists 
(select 1 from test1..pozdoc d 
where p.Subunitate=d.Subunitate and p.Tip=d.tip and p.Numar=d.Numar and p.Data=d.Data and p.Numar_pozitie=d.Numar_pozitie)
and p.Subunitate=t.Subunitate and p.Tip=t.tip and p.Numar=t.Numar and p.Data=t.Data and p.Numar_pozitie=t.Numar_pozitie) 
--order by s.data_stergerii desc
--order by p.data_operarii desc, p.ora_operarii desc

--select * from antetbonuri a where not exists
--(select 1 from tet..antetBonuri b where b.IdAntetBon=a.IdAntetBon)

--select * from b