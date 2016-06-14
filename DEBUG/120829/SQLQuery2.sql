select * from bp b inner join antetBonuri a on a.IdAntetBon=b.idAntetBon
where ISNULL(a.Gestiune,b.Loc_de_munca) like '213.1'
and b.Cod_produs='100-ISO4-16-BL'
select * from bt