--select top 1 * from antetBonuri a order by a.IdAntetBon desc
select * from bp where IdAntetBon=1105

select * -- update a set contract=bp.contract
from antetbonuri a join bp on bp.IdAntetBon=a.IdAntetBon
where isnull(bp.contract,'')<>'' and isnull(a.Contract,'')=''

select * -- update a set Comanda=bp.Comanda_asis
from antetbonuri a join bp on bp.IdAntetBon=a.IdAntetBon
where isnull(bp.Comanda_asis,'')<>'' and isnull(a.Comanda,'')=''

SELECT * FROM antetBonuri A where a.Comanda is not null
order by a.IdAntetBon desc
SELECT * FROM BT