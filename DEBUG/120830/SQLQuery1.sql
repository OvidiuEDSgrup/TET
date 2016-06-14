select bt.idAntetBon,* from bt left join antetBonuri a on a.IdAntetBon=bt.idAntetBon
--except
select bp.IdAntetBon from bp left join antetBonuri a on a.IdAntetBon=bp.idAntetBon
--where bt.Cod_produs='4300902006021'