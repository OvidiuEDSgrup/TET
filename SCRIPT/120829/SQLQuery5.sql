select p.Factura, * from pozdoc p where p.Tip in ('ac','te')  and p.Stare=5 and p.Numar not like '[0-9]00[0-9][0-9]'
and p.Factura<>''