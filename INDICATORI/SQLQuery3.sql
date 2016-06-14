select sum(p.Cantitate*p.Pret_vanzare-p.Cantitate*p.Pret_de_stoc) 
from pozdoc p inner join calstd c on c.Data=p.Data left join nomencl n on n.Cod=p.Cod 
where p.tip in ('AP','AS','AC')
 EXPANDEZ({c.DATA_LUNII},{p.LOC_DE_MUNCA},{p.tert},{n.grupa})