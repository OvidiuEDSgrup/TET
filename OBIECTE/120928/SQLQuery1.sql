select * from bp left join antetBonuri a on bp.IdAntetBon=a.IdAntetBon
where bp.IdAntetBon=1012 and bp.Cod_produs='200-R160212'

select * from tet..pozdoc p where p.Numar like '10003' and p.Data='2012-08-03' and p.Cod like '200-R160212'
select * from stocuri s where s.Cod_gestiune='211.1' and s.Cod like '200-R160212'