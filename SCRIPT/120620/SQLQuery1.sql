select * 
--update p set Loc_de_munca=g.Loc_de_munca
from pozdoc p inner join gestcor g on g.Gestiune=p.Gestiune 
where p.Tip in ('TE','AC') and g.Loc_de_munca<>p.Loc_de_munca and LEFT(p.Gestiune,3) in ('211','212','213')
--and p.Numar='20002' and p.Data='2012-06-14'
and p.Data between '2012-05-01' and '2012-06-30'
and exists 
(select 1 from bp b where b.Data=p.Data and p.Numar=CONVERT(varchar(8),b.Casa_de_marcat*10000+b.Numar_bon))
order by data

select * 
--update p set Loc_munca=g.Loc_de_munca
from doc p inner join gestcor g on g.Gestiune=p.Cod_gestiune 
where p.Tip in ('TE','AC') and g.Loc_de_munca<>p.Loc_munca and LEFT(p.Cod_gestiune,3) in ('211','212','213')
--and p.Numar='20002' and p.Data='2012-06-14'
and p.Data between '2012-05-01' and '2012-06-30'
and exists 
(select 1 from bp b where b.Data=p.Data and p.Numar=CONVERT(varchar(8),b.Casa_de_marcat*10000+b.Numar_bon))
order by data

select * from antetBonuri a
 --where a.Numar_bon=2 and a.Casa_de_marcat=2 and a.Data_bon='2012-06-14'
order by a.Data_bon

select * from bp a
 --where a.Numar_bon=2 and a.Casa_de_marcat=2 and a.Data_bon='2012-06-14'
order by a.Data

select * 
--update a set a.Loc_de_munca=g.Loc_de_munca
from antetBonuri a inner join gestcor g on g.Gestiune=a.Gestiune 
 --where a.Numar_bon=2 and a.Casa_de_marcat=2 and a.Data_bon='2012-06-14'
where a.Data_bon between '2012-05-01' and '2012-06-30'
and g.Loc_de_munca<>a.Loc_de_munca
order by a.Data_bon