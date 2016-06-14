select * 
-- delete p
from pozdoc p where p.Numar='10001' and p.Data='2012-08-23' 
and p.Cod like '10310014'
select a.Gestiune,bp.* from bp left join antetBonuri a on a.IdAntetBon=bp.IdAntetBon
where a.Data_bon='2012-08-01' and bp.Cod_produs like 'disc%'
