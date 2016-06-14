select * from pozdoc p where '119255' in (p.Numar,p.Factura)
select p.tert,* from sysspd p where '119255' in (p.Numar,p.Factura) order by p.Data_stergerii desc
select * from terti t where t.Tert in ('RO26132528','RO14140365')