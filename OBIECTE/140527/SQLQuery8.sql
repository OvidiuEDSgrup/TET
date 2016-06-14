alter table pozdoc disable trigger all
--select REPLACE(p.Gestiune,'211.','210.'),p.Gestiune_primitoare,* -- 
update p set Gestiune_primitoare=REPLACE(p.Gestiune,'211.','210.')
from pozdoc p where p.Tip='AC' and p.Gestiune like '211.%' and p.Gestiune_primitoare<>REPLACE(p.Gestiune,'211.','210.')
alter table pozdoc enable trigger all

select top 200 * from antetBonuri a 
where a.Casa_de_marcat=10 
order by a.IdAntetBon desc

select top 200 * from bp a 
where a.Casa_de_marcat=10 
order by a.IdAntetBon desc


alter table bp disable trigger all
--select REPLACE(p.Loc_de_munca,'210.','211.'),p.Loc_de_munca,* -- 
update p set Loc_de_munca=REPLACE(p.Loc_de_munca,'210.','211.')
from bp p where p.Gestiune like '210.%' and p.Loc_de_munca<>REPLACE(p.Loc_de_munca,'210.','211.')
alter table bp enable trigger all