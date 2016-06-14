select * from pozdoc p where p.Numar in ('4393','9310029')
select n.Denumire,p.* from sysspd p inner join nomencl n on n.cod=p.cod 
where p.Numar in ('4393','9310029')

