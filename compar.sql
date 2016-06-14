select Subunitate,t.Tip,t.Numar,t.Cod,t.Data,t.Gestiune,t.Cantitate,t.Pret_valuta,t.Pret_de_stoc,t.Adaos,t.Pret_vanzare,t.Pret_cu_amanuntul,t.TVA_deductibil,t.Cota_TVA,t.Utilizator,t.Data_operarii,t.Ora_operarii,t.Cod_intrare,t.Cont_de_stoc,t.Cont_corespondent,t.TVA_neexigibil,t.Pret_amanunt_predator,t.Tip_miscare,t.Locatie,t.Data_expirarii,t.Numar_pozitie,t.Loc_de_munca,t.Comanda,t.Barcod,t.Cont_intermediar,t.Cont_venituri,t.Discount,t.Tert,t.Factura,t.Gestiune_primitoare,t.Numar_DVI,t.Stare,t.Grupa,t.Cont_factura,t.Valuta,t.Curs,t.Data_facturii,t.Data_scadentei,t.Procent_vama,t.Suprataxe_vama,t.Accize_cumparare,t.Accize_datorate,t.Contract,t.Jurnal
--,t.detalii 
from tet..pozdoc p where p.Data between '2012-01-01' and '2012-04-30'
except
select Subunitate,t.Tip,t.Numar,t.Cod,t.Data,t.Gestiune,t.Cantitate,t.Pret_valuta,t.Pret_de_stoc,t.Adaos,t.Pret_vanzare,t.Pret_cu_amanuntul,t.TVA_deductibil,t.Cota_TVA,t.Utilizator,t.Data_operarii,t.Ora_operarii,t.Cod_intrare,t.Cont_de_stoc,t.Cont_corespondent,t.TVA_neexigibil,t.Pret_amanunt_predator,t.Tip_miscare,t.Locatie,t.Data_expirarii,t.Numar_pozitie,t.Loc_de_munca,t.Comanda,t.Barcod,t.Cont_intermediar,t.Cont_venituri,t.Discount,t.Tert,t.Factura,t.Gestiune_primitoare,t.Numar_DVI,t.Stare,t.Grupa,t.Cont_factura,t.Valuta,t.Curs,t.Data_facturii,t.Data_scadentei,t.Procent_vama,t.Suprataxe_vama,t.Accize_cumparare,t.Accize_datorate,t.Contract,t.Jurnal
--,t.detalii 
from test..pozdoc p where p.Data between '2012-01-01' and '2012-04-30'

select MAX(data) from pozdoc

select * from ##sitvanzaritet
except
select * from ##sitvanzaritest

select t.*,tt.*
from ##sitvanzaritet t
	full outer join ##sitvanzaritest tt on t.agent=tt.agent and t.client=tt.client and t.grupa=tt.grupa 
		and t.articol=tt.articol and t.echipa=tt.echipa
where t.pretVanzare<>tt.pretVanzare or t.pretIntrare<>tt.pretIntrare

select 'TET' AS BD,SUM(cantitate*pretVanzare) valvanzare, SUM(cantitate*pretIntrare) valintrare from ##sitvanz2tet1
--except
select 'TEST' AS BD,SUM(cantitate*pretVanzare) valvanzare, SUM(cantitate*pretIntrare) valintrare from ##sitvanz2test1
