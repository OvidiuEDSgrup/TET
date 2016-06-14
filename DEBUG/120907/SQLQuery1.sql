select * from bt
select * from stocuri s where s.Cod_gestiune='212.1' and abs(s.stoc)>=0.001
select * from bp inner join antetBonuri a on a.IdAntetBon=bp.IdAntetBon
where bp.Casa_de_marcat=2 and bp.Data='2012-09-06' 
select * from pozdoc p  where p.Tip IN ('AC','TE') 
and p.Numar like 20000+2 
and p.Data='2012-09-06'

select * from pozdoc p where p.Cod='200-R160212'
and '212.1IMPL2' IN (rtrim(p.Gestiune)+rtrim(p.Cod_intrare),RTRIM(p.Gestiune_primitoare)+RTRIM(p.grupa))
order by p.Data

select * from pozdoc p where p.Cod='200-R160212'
and '212.1IMPL212' IN (rtrim(p.Gestiune)+rtrim(p.Cod_intrare),RTRIM(p.Gestiune_primitoare)+RTRIM(p.grupa))
order by p.Data

select * from pozdoc p where p.Cod='200-R160212'
and '212IMPL212' IN (rtrim(p.Gestiune)+rtrim(p.Cod_intrare),RTRIM(p.Gestiune_primitoare)+RTRIM(p.grupa))
order by p.Data

select * from istoricstocuri s where s.Cod_gestiune='212.1' 
and s.Cod='200-R160212'
and abs(s.stoc)>=0.001