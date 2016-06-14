select p.idPozDoc,p.Cantitate,p.Data,p.Numar,l.*,r.* 
from pozdoc p left join LegaturiStornare l on l.idSursa=p.idPozDoc left join pozdoc r on r.idPozDoc=l.idStorno
where p.Numar like 'AG940966'

select * -- delete s
from LegaturiStornare s join pozdoc t on t.idPozDoc=s.idSursa
where s.idStorno=540107 and s.idSursa=499975