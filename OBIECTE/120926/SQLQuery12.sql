select distinct p.Utilizator,Data_operarii=convert(date,p.Data_operarii)
,p.Ora_operarii, p.Factura,p.Cont_factura,Data_facturii=convert(date,p.Data_facturii)
--,* 
from pozdoc p where '9430206' in (p.Numar,p.Factura) 
select * from doc p where '9430206' in (p.Numar,p.Factura) 

select * from yso_syssd p where '9430206' in (p.Numar,p.Factura) 
select * from sysspd p where '9430206' in (p.Numar,p.Factura) 