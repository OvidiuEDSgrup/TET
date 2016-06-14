select * from antetBonuri a where a.Factura like '9410905'
select * from pozdoc p where p.Factura like '9410905'
select * from pozadoc p where '9410905' in (p.Factura_dreapta,p.Factura_stinga)