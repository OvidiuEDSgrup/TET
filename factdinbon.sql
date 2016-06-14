select *
--avnefac.Terminal,avnefac.Data_facturii, avnefac.Factura, antetFactura.Data_facturii, antetFactura.Factura, antetFactura.tert, a.Data_facturii, a.Factura, a.tert, b.Cod_produs, b.pret, terti.Tert,left(convert(char(16),convert(money,round(sum(b.cantitate),3)),2),15) as cantitate
FROM avnefac,bonuri b,nomencl n, antetBonuri a/*antetul fiecarui bon*/, terti, antetBonuri antetFactura
where avnefac.numar=a.Factura and avnefac.Data=a.Data_facturii and a.casa_de_marcat=b.casa_de_marcat and b.data=a.Data_bon and b.numar_bon=a.Numar_bon and b.cod_produs=n.cod and b.tip='21' and a.Tert=terti.tert and avnefac.numar=antetFactura.Factura and avnefac.Data=antetFactura.Data_facturii and antetFactura.chitanta=0
--GROUP BY avnefac.Terminal,avnefac.Data_facturii, avnefac.Factura, antetFactura.Data_facturii, antetFactura.Factura, antetFactura.tert, a.Data_facturii, a.Factura, a.tert, b.Cod_produs, b.pret, terti.Tert 
--having sum(b.cantitate)<>0

select * from avnefac where numar='9410141'
select * from antetBonuri a where a.Factura='9410141'
select * from bp b where b.Tip='21' and b.Casa_de_marcat=1 and b.Numar_bon in ('1','9410141') and b.Data='2012-05-10'
select * from bt b where b.Tip='21' and b.Casa_de_marcat=1 and b.Numar_bon in ('1','9410141') and b.Data='2012-05-10'

select Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data
--, Ora
, Tip
, Vinzator
, Client
, Cod_citit_de_la_tastatura, CodPLU
, Cod_produs, Categorie, UM
, Cantitate, Cota_TVA, Tva
, Pret
--, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, idAntetBon, lm_real, Comanda_asis, Contract, Gestiune
from bt
except
select Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data
--, Ora
, Tip
, Vinzator
, Client
, Cod_citit_de_la_tastatura, CodPLU
, Cod_produs, Categorie, UM
, Cantitate, Cota_TVA, Tva
, Pret
--, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, idAntetBon, lm_real, Comanda_asis, Contract, Gestiune
from bp


select Casa_de_marcat
--, Factura_chitanta
, Numar_bon, Numar_linie, Data
--, Ora
--, Tip
, Vinzator
--, Client
--, Cod_citit_de_la_tastatura, CodPLU
--, Cod_produs, Categorie, UM
--, Cantitate, Cota_TVA, Tva
--, Pret
--, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, idAntetBon, lm_real, Comanda_asis, Contract, Gestiune
from bp
intersect
select Casa_de_marcat
--, Factura_chitanta
, Numar_bon, Numar_linie, Data
--, Ora
--, Tip
, Vinzator
--, Client
--, Cod_citit_de_la_tastatura, CodPLU
--, Cod_produs, Categorie, UM
--, Cantitate, Cota_TVA, Tva
--, Pret
--, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, idAntetBon, lm_real, Comanda_asis, Contract, Gestiune
from
(select Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data
--, Ora
, Tip
, Vinzator
, Client
, Cod_citit_de_la_tastatura, CodPLU
, Cod_produs, Categorie, UM
, Cantitate, Cota_TVA, Tva
, Pret
--, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, idAntetBon, lm_real, Comanda_asis, Contract, Gestiune
from bt
except
select Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data
--, Ora
, Tip
, Vinzator
, Client
, Cod_citit_de_la_tastatura, CodPLU
, Cod_produs, Categorie, UM
, Cantitate, Cota_TVA, Tva
, Pret
--, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, idAntetBon, lm_real, Comanda_asis, Contract, Gestiune
from bp) t

-- delete bt