select *
-- update pozdoc set Loc_de_munca=g.Loc_de_munca
from pozdoc p inner join gestcor g on p.Gestiune=g.Gestiune
where p.Tip='AC' and p.Data between '2012-04-01' and '2012-05-08' 
and p.Loc_de_munca <>g.Loc_de_munca

select *
-- update doc set Loc_munca=g.Loc_de_munca
from doc p inner join gestcor g on p.cod_Gestiune=g.Gestiune
where p.Tip='AC' and p.Data between '2012-04-01' and '2012-05-08' 
and p.Loc_munca <>g.Loc_de_munca

select * from sysspd s order by s.Data_stergerii desc