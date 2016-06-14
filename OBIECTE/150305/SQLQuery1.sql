select stare=max(coalesce(n.stare*10-(case when n.cantitate<p.cantitate then 5 else 0 end),p.stare,-15))
	+(case when COUNT(distinct coalesce(n.stare*10-(case when n.cantitate<p.cantitate then 5 else 0 end),p.stare,-15))>1 then -5 else 0 end) 
,c.numar, c.data, c.idContract
from PozContracte p join contracte c on c.idContract=p.idContract
	left join necesaraprov n on n.Numar=c.numar and n.Data=c.data and n.Numar_pozitie=p.idPozContract
where isnumeric(coalesce(n.stare,0))=1
and c.tip='RN' 
group by c.numar, c.data, c.idContract

select * from PozContracte p where p.idContract=71
select * from necesaraprov n where n.Numar='SB910007'