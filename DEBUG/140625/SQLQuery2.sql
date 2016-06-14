select * from stocuri s where s.Cod='HP20SLO' and s.Cod_intrare='1140443001'
select p.Gestiune_primitoare,p.Grupa,p.Cod_intrare,* 
from pozdoc p where p.Cod='HP20SLO' and '1140443001' in (p.Cod_intrare,p.Grupa) and '210.sb' in (p.Gestiune,p.Gestiune_primitoare)

select p.Gestiune_primitoare,p.Grupa,p.Cod_intrare,* 
from pozdoc p where p.Cod='HP20SLO' and '1140443001' in (p.Cod_intrare,p.Grupa) and '101' in (p.Gestiune,p.Gestiune_primitoare)
order by p.Data