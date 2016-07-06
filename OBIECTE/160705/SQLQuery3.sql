select * from pozdoc p where 'AG982157' in (p.Contract,p.Factura)
select * from sysspd p where 'AG982157' in (p.Contract,p.Factura) 
order by p.Data_stergerii desc