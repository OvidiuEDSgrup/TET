select * from pozdoc p 
inner join nomencl n on n.Cod=p.Cod
where p.tip in ('AC','TE')
and p.data='2012-08-03' and p.Numar like 10000+3

select * from sysspd p 
inner join nomencl n on n.Cod=p.Cod
where p.tip in ('AC','TE')
and p.data='2012-08-03' and p.Numar like 10000+3
order by p.data_stergerii desc

select b.* from BONURI b where b.Casa_de_marcat=1 and b.Numar_bon=3 and b.Data='2012-08-03'
and b.Tip='21'

select distinct p.cod from sysspd p 
inner join nomencl n on n.Cod=p.Cod
where p.tip in ('AC','TE')
and p.data='2012-08-03' and p.Numar like 10000+3
and p.Cod not in 
(select p.Cod from pozdoc p 
inner join nomencl n on n.Cod=p.Cod
where p.tip in ('AC','TE')
and p.data='2012-08-03' and p.Numar like 10000+3)