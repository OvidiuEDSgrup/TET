select *
	-- update p set loc_de_munca=g.Loc_de_munca
from pozdoc p inner join gestcor g on g.Gestiune=p.Gestiune 
where p.Tip in ('AC') and LEFT(p.Gestiune,3) in ('211','212','213') 
and p.Loc_de_munca<>g.Loc_de_munca
order by data desc

select *
	-- update p set Loc_munca=g.Loc_de_munca
from doc p inner join gestcor g on g.Gestiune=p.Cod_gestiune 
where p.Tip in ('AC') and LEFT(p.Cod_gestiune,3) in ('211','212','213') 
and p.Loc_munca<>g.Loc_de_munca
order by data desc