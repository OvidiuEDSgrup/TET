--*** creem de fiecare data pt. cazurile in care alteram structurile...
create view Bonuri
as
SELECT Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, 
		Cantitate, Cota_TVA, Tva, Pret, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount,
		lm_real, Comanda_asis,[Contract], idAntetBon, idPozcontract, detalii
	from bt
union all
SELECT Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, 
		Cantitate, Cota_TVA, Tva, Pret, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount,
		lm_real, Comanda_asis,[Contract], idAntetBon, idPozcontract, detalii
	from bp
