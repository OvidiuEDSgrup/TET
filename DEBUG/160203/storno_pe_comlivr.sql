select p.[Contract],p.Loc_de_munca,* from pozdoc p where p.Cod='50-ISO4-20-RO' and  'AILOC21023' in (p.Cod_intrare,p.Grupa) 
order by p.Data, p.Tip_miscare desc, p.Tip desc

exec RefacereStocuri '101','50-ISO4-20-RO',null,null,null,null

select s.[Contract],s.Loc_de_munca,* from stocuri s where s.Cod='50-ISO4-20-RO' and s.Cod_gestiune like '101' and s.Cod_intrare like 'AILOC21023'