--select * from antetbonuri a order by data_bon desc
--select * from bp order by data desc
--select * from par where par.parametru like 'NUTEAC'
select * from bp inner join antetBonuri a on a.IdAntetBon=bp.IdAntetBon
where '700' in (a.Gestiune,bp.Gestiune,bp.lm_real)
and Comanda_asis is null