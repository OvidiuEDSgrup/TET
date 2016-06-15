--***
create view facturiE as 
select 'F' as Ce, Subunitate, Loc_de_munca, Tip, Factura, Tert, Data, Data_scadentei, Valoare, TVA_11, TVA_22, Valuta, Curs, Valoare_valuta, Achitat, Sold, Cont_de_tert, Achitat_valuta, Sold_valuta, Comanda, Data_ultimei_achitari from facturi 
union all
select 'E', Subunitate, Loc_de_munca, (case when tip='I' then 0x46 else 0x54 end), Nr_efect, Tert, Data, Data_scadentei, Valoare, 0, 0, Valuta, Curs, Valoare_valuta, Decontat, Sold, Cont, Decontat_valuta, Sold_valuta, Comanda, Data_decontarii from efecte
