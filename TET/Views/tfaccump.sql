create view tfaccump as
select facturi.cont_de_tert,facturi.data,facturi.data_scadentei,terti.denumire,facturi.factura,facturi.valuta,facturi.valoare+facturi.tva_11+facturi.tva_22 as 'Valoare',facturi.achitat,facturi.sold,
facturi.valoare_valuta,facturi.sold_valuta from
facturi,terti where
facturi.tip=0x54 and facturi.tert=terti.tert and facturi.sold<>0