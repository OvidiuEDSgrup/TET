select distinct p.Utilizator,Data_operarii=convert(date,p.Data_operarii)--,p.Ora_operarii
,p.Factura,p.Cont_factura,Data_facturii=convert(date,p.Data_facturii)
--,* 
from pozdoc p 
where p.factura in ('9410009','9410012','9410013','9410018','9410019','9410014','9410017','9410001','9410020')
order by p.Factura
--select * 
---- delete d
--from doc d where d.Numar like '9410014'

select distinct p.Utilizator,Data_operarii=convert(date,p.Data_operarii)--,p.Ora_operarii
,p.Factura,p.Cont_factura,Data_facturii=convert(date,p.Data_facturii)
,p.Stergator,Data_stergerii=convert(date,p.data_stergerii)
--,* 
from sysspd p 
where p.factura in ('9410009','9410012','9410013','9410018','9410019','9410014','9410017','9410001','9410020')
order by p.Factura
--select * 
---- delete d
--from doc d where d.Numar like '9410014'