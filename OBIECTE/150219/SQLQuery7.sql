update necesaraprov set 
stare=(case when stare='0' then '0' when isnull(p.receptionat, 0)>=n.cantitate then '3' when isnull(p.comandat, 0)>0 then '2' else '1' end)
from necesaraprov n 
left outer join
	(select p.comanda_livrare as numar, p.data_comenzii as data, p.cod, sum(p.cant_comandata) as comandat, sum(p.cant_receptionata) as receptionat
	from pozaprov p
	where p.tip='N' and p.beneficiar='' 
	group by p.comanda_livrare, p.data_comenzii, p.cod) p
on n.numar=p.numar and n.data=p.data and n.cod=p.cod
