select top 1000 p.Cont_intermediar,p.Cont_de_stoc,p.Cont_corespondent,p.Cont_venituri,* 
from pozdoc p where p.Subunitate='1' and p.Tip in ('AC','AP')
--and (p.Cont_de_stoc like '357%' or p.Gestiune like '700%')
order by p.idPozDoc desc

select top 1000 p.Cont_intermediar,p.Cont_de_stoc,p.Cont_corespondent,p.Cont_venituri,p.Gestiune_primitoare,* 
from pozdoc p where p.Subunitate='1' and p.Tip in ('TE')
and (p.Cont_de_stoc like '357%' or p.Gestiune_primitoare like '700%')
--and p.Cont_intermediar<>''
order by p.idPozDoc desc