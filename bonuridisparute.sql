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
