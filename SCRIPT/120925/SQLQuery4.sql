select * from pozdoc p where '9410169' in (p.Numar,p.Factura)
select * 
-- delete p
from doc p where '9410169' in (p.Numar,p.Factura)

select * from antetBonuri p where '9410169' in (p.Numar_bon,p.Factura)

select * from pozadoc p where '9410169' in (p.Factura_dreapta,p.Factura_stinga)