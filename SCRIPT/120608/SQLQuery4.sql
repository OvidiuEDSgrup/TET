select * from pozdoc p where p.Tip IN ('CM','PP') and Numar like '61/03' and p.Data='2012-03-29'
select * from pozdoc p where p.Tip IN ('AP') and p.Cod like 'PKSONEP150_11       ' and p.Cod_intrare like '61/03%' 
and p.Data between '2012-04-01' and '2012-04-30'
select * from pozdoc p where p.Tip='TE' and p.Gestiune='101' and p.Cod like 'PKSONEP150_11       ' and p.Cod_intrare like '61/03%' 
