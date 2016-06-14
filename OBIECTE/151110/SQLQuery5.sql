select * from pozaprov p where p.Tip='N' --and p.Beneficiar<>''
order by p.Data desc

select * from Contracte c where c.tip='RN' 
--AND c.tert is not null

select n.Numar,data,cod,count(1)
from necesaraprov n
group by n.Numar,data,cod
having count(1)>1
select * from necesaraprov p
where p.Numar like 'BV910028'
and p.Cod in (
'3021043             '
,'3305055268480       '
)

select * from pozaprov p where p.Comanda_livrare like 'BV910028'
and p.Cod in (
'3021043             '
,'3305055268480       '
)

select * from pozcon p where p.Contract in 
(
'8520                '
,'8547                '
)
and p.Cod in (
'3021043             '
,'3305055268480       '
)

select * from pozdoc p where p.Contract in 
(
'8520                '
,'8547                '
)
and p.Cod in (
'3021043             '
,'3305055268480       '
)
