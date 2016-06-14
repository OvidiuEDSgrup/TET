alter table pozdoc disable trigger all
/*
select p.Factura,* 
--*/ update p set factura='9420640'
from pozdoc p where p.Factura like '9420640%'
alter table pozdoc enable trigger all
exec RefacereFacturi null,null,null,null