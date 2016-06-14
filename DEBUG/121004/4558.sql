select * from pozdoc p where '9420286' in (p.Numar,p.Factura)
select * from pozadoc p where '9420286' in (p.Factura_dreapta,p.Factura_stinga)
select * from antetBonuri p where '9420286' in (p.Numar_bon,p.Factura)