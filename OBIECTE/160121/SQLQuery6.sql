select * from bt b where b.Data='2016-01-19'
select * from bp b where b.Data='2016-01-15' and b.Loc_de_munca like '%nt'

select p.Gestiune_primitoare,* from pozdoc p where p.Tert='1720906270600' and 
p.Cod in ('VB-060504-B','VB-060504-R')