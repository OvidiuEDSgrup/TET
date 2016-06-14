select * from syssc c where c.Cont like '411%'
order by c.Data_stergerii desc

select p.Cod_intrare,p.Factura,* from pozdoc p where 'GL940478' in (LEFT(p.Factura,8),LEFT(p.Cod_intrare,8))

select p.Cod_intrare,p.Factura,* from sysspd p where 'GL940478' in (LEFT(p.Factura,8),LEFT(p.Cod_intrare,8))
order by p.Data_stergerii desc
