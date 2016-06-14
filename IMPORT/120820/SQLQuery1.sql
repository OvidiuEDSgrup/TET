select * from pozdoc p  where p.Tip='AP' and p.Cantitate<0 and p.Cod_intrare<>'' and p.Utilizator like 'MAG%' and p.Stare='3'
order by p.Data
select * from sysspd p  where p.Tip='AP' and p.Cantitate<0 and p.Cod_intrare<>'' and p.Utilizator like 'MAG%' and p.Stare='3'
order by p.Data