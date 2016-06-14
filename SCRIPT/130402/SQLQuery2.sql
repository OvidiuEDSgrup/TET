select p.Factura,p.* 
from stocuri s 
outer apply (select * from pozdoc p where p.Cod=s.Cod and s.Cod_gestiune in (p.Gestiune,p.Gestiune_primitoare)
and s.Cod_intrare in (p.Cod_intrare,p.Grupa)) p
where s.Cod_gestiune like '700.cj'
and s.Cod like 'malk50_11%'