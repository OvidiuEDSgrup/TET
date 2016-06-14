select * from bp a
where not exists 
(select 1 from tet..bp b where b.IdAntetBon=a.IdAntetBon and b.Numar_linie=a.Numar_linie)
and a.IdAntetBon is null

--set identity_insert TET..antetbonuri off
--insert tet..antetBonuri
--(Casa_de_marcat,	Chitanta,	Numar_bon,	Data_bon,	Vinzator,	Factura,	Data_facturii,	Data_scadentei,	Tert,	Gestiune
--,	Loc_de_munca,	Persoana_de_contact,	Punct_de_livrare,	Categorie_de_pret,	Contract,	Comanda,	Observatii
--,	Explicatii,	UID,	Bon,	IdAntetBon	)
select 
a.Casa_de_marcat,a.Chitanta,a.Numar_bon,a.Data_bon,a.Vinzator,a.Factura,a.Data_facturii,a.Data_scadentei,a.Tert,a.Gestiune
,a.Loc_de_munca,a.Persoana_de_contact,a.Punct_de_livrare,a.Categorie_de_pret,a.Contract,a.Comanda,a.Observatii
,a.Explicatii,a.UID,a.Bon,a.IdAntetBon
from antetBonuri a left join tet..antetbonuri b on b.Data_bon=a.Data_bon and b.Casa_de_marcat=a.Casa_de_marcat and b.Vinzator=a.Vinzator
and b.Numar_bon=a.Numar_bon 
where b.Numar_bon is null

--set identity_insert TET..bp on
--insert tet..bp
--(Casa_de_marcat,	Factura_chitanta,	Numar_bon,	Numar_linie,	Data,	Ora,	Tip,	Vinzator,	Client
--,	Cod_citit_de_la_tastatura,	CodPLU,	Cod_produs,	Categorie,	UM,	Cantitate,	Cota_TVA,	Tva,	Pret,	Total
--,	Retur,	Inregistrare_valida,	Operat,	Numar_document_incasare,	Data_documentului,	Loc_de_munca,	Discount
--,	IdAntetBon,	IdPozitie,	lm_real,	Comanda_asis,	Contract)
select 
 a.Casa_de_marcat,a.Factura_chitanta,a.Numar_bon,a.Numar_linie,a.Data,a.Ora,a.Tip,a.Vinzator,a.Client
,a.Cod_citit_de_la_tastatura,a.CodPLU,a.Cod_produs,a.Categorie,a.UM,a.Cantitate,a.Cota_TVA,a.Tva,a.Pret,a.Total
,a.Retur,a.Inregistrare_valida,a.Operat,a.Numar_document_incasare,a.Data_documentului,a.Loc_de_munca,a.Discount
,a.IdAntetBon,a.IdPozitie,a.lm_real,a.Comanda_asis,a.Contract
from bp a left join tet..bp b on b.Data=a.Data and b.Casa_de_marcat=a.Casa_de_marcat and b.Vinzator=a.Vinzator
and b.Numar_bon=a.Numar_bon and b.Numar_linie=a.Numar_linie
where b.Numar_bon is null