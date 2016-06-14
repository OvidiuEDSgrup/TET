select row_number() over(partition by p.subunitate,p.tip,p.data,p.numar order by p.cod)
,p.idPozDoc,*
from LegaturiStornare l join pozdoc p on p.idPozDoc=l.idSursa
where p.Numar='IF940780'
--for xml raw(
order by p.cod
--order by p.Data desc, p.Numar desc,p.idPozDoc desc
select p.Tip,p.Data,p.Numar, COUNT(distinct s.Tip+rtrim(s.Data)+s.Numar)
from LegaturiStornare l join pozdoc p on p.idPozDoc=l.idSursa
join pozdoc s on s.idPozDoc=l.idStorno
group by p.Tip,p.Data,p.Numar
having COUNT(distinct s.Tip+RTRIM(s.Data)+s.Numar)>1
order by p.data desc, p.Tip desc, p.Numar desc