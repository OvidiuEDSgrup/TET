select p.Factura,p.Stare,* from pozdoc p where p.Tip='AP' order by p.Data_operarii desc, p.Ora_operarii desc
select * from doc d where YEAR(d.data)=2012 and MONTH(d.data)=6

select * from incfact i 
where 1=1
--and '118183' in (i.Numar_factura)
and i.Numar_pozitie>1