select * from facturi f where f.Tert='RO14896874' and f.Factura like 'IF94005_'
select f.Contract,n.Denumire,f.factura,f.Cont_factura,* 
from pozdoc f join nomencl n on n.Cod=f.cod
where f.Tert='RO14896874' and f.Factura like 'IF94005_'
--alter table facturi disable trigger all
--exec RefacereFacturi null,null,null,null
--alter table facturi enable trigger all
--sp_helptrigger facturi

select * from sysst t where t.Tert='RO14896874' order by t.Data_stergerii desc