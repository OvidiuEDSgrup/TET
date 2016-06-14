select * from pozdoc p where '9410401' in (p.Numar,p.Factura)
select * from pozadoc p where '9410401' in (p.Factura_dreapta,p.Factura_stinga)
select * from bp right join antetBonuri a on a.IdAntetBon=bp.IdAntetBon 
where '9410401' in (a.Factura,a.Numar_bon)
select * from pozdoc p where p.Tip='AC' and p.Numar in ('10001','10004') and p.Data between '2012-08-28' and '2012-08-29'
select * from ##factemise