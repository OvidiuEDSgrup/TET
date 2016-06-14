select top 20 *
from pozdoc p 
where p.Tip='TE' and '110' in (p.Gestiune,p.Gestiune_primitoare)
and p.Cantitate<0
order by p.idPozDoc desc