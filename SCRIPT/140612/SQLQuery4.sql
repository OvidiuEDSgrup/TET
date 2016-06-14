SELECT     TOP (20000) Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, 
                      TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal, detalii, tip_tva, marca, 
                      decont, efect, idPozPlin
FROM         pozplin
WHERE     (Data = '2014-03-24') AND (Cont = '5311.1') and Plata_incasare='PD'and marca='146'

update pozplin
set decont='146/1' where Data = '2014-03-24' AND Cont = '5311.1' and Plata_incasare='PD'and marca='146'