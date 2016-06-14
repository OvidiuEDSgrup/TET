select * from pozdoc p where '9430223' in (p.numar,p.Factura)

select * from pozadoc p where '9430223' in (p.Factura_dreapta,p.Factura_stinga)

select * from antetBonuri p where '9430223' in (p.Factura,p.Numar_bon)