select * from test1..bp t where t.IdAntetBon not in 
(select b.IdAntetBon from tet..bp b)

-- insert tet..bp (Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, Pret, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, lm_real, Comanda_asis, Contract)
select				Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs
, Categorie, UM, Cantitate, Cota_TVA, Tva, Pret, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului
, Loc_de_munca, Discount, lm_real, Comanda_asis, Contract
from test1..bp t where not exists 
(select 1 from tet..bp b
where b.Data=t.Data and b.Casa_de_marcat=t.Casa_de_marcat 
and b.Vinzator=t.Vinzator and b.Numar_bon=t.Numar_bon and b.Numar_linie=t.Numar_linie)

-- insert tet..pozdoc
select * from test1..pozdoc t where t.Tip IN ('TE','AC') and not exists
(select 1 from testov..pozdoc p where p.Tip IN ('TE','AC') and p.Subunitate=t.Subunitate and p.Tip=t.Tip and p.Numar=t.Numar 
and p.Data=t.Data and p.Numar_pozitie=t.Numar_pozitie)

declare @datainf date, @datasup date, @tip char(2)
select @datainf='2012-01-01', @datasup='2012-02-29', @tip='AC'

select  
ISNULL(CONVERT(varchar,b.Numar),'NUEXISTA') as Numar_test,ISNULL(CONVERT(varchar,b.Data,121),'NUEXISTA') as Data_test,ISNULL(b.cod,'NUEXISTA') as Cod_produs_test
	,ISNULL(p.Numar,'NUEXISTA') as Numar_ac,ISNULL(CONVERT(varchar,p.Data,121),'NUEXISTA') as Data_ac,ISNULL(p.Cod,'NUEXISTA') as Cod_produs_ac
	,b.Cantitate as Cantitate_bon,p.cantitate as Cantitate_ac,b.Valoare as Valoare_bon,p.Valoare as Valoare_ac
,*
from (select p.Numar,p.Data,p.Cod,SUM(p.Cantitate) as cantitate
		,max(p.Pret_cu_amanuntul) as Pret_cu_amanuntul,max(p.Pret_amanunt_predator) as Pret_amanunt_predator,max(p.Pret_vanzare) as Pret_vanzare 
		,SUM(convert(decimal(15,2),p.Cantitate*p.Pret_amanunt_predator)) as Valoare
	from test1..pozdoc p where p.Subunitate='1' and p.Tip=@tip and p.Data between @datainf and @datasup
	group by p.Numar,p.Data,p.Cod) b
	full outer join 
	(select p.Numar,p.Data,p.Cod,SUM(p.Cantitate) as cantitate
		,max(p.Pret_cu_amanuntul) as Pret_cu_amanuntul,max(p.Pret_amanunt_predator) as Pret_amanunt_predator,max(p.Pret_vanzare) as Pret_vanzare 
		,SUM(convert(decimal(15,2),p.Cantitate*p.Pret_amanunt_predator)) as Valoare
	from tet..pozdoc p where p.Subunitate='1' and p.Tip=@tip and p.Data between @datainf and @datasup
	group by p.Numar,p.Data,p.Cod) p
	on p.Numar=b.Numar and p.Data=b.Data and p.Cod=b.cod
where b.cod is null or p.Cod is null  
	or isnull(b.Cantitate,0)<>isnull(p.cantitate,0) or abs(isnull(b.Valoare,0)-isnull(p.Valoare,0))>0.1
	
select Subunitate, Tip, Numar, Cod, Data
--, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, Accize_cumparare, Accize_datorate, Contract, Jurnal
from test1..pozdoc t where t.Tip='AC' and t.Data between @datainf and @datasup
except
select Subunitate, Tip, Numar, Cod, Data
--, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, Accize_cumparare, Accize_datorate, Contract, Jurnal
from tet..pozdoc t where t.Tip='AC' and t.Data between @datainf and @datasup