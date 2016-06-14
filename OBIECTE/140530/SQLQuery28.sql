select p.Cont_intermediar,*
from pozdoc p
	inner join gestiuni g on p.Subunitate=g.Subunitate and +(case when p.tip='AT' then p.Gestiune_primitoare else p.Gestiune end)=g.cod_gestiune
	inner join nomencl n on p.Cod=n.Cod
	where
		p.tip_miscare='E' 
		--and g.tip_gestiune in ('A','V')
		/* Doar la conturile de stoc de marfa */
		--and LEFT(p.Cont_de_stoc,3) IN ('371','357')
		--and not (tip_gestiune='V' and p.Tip='AP')
		and p.Numar like 'CJ%'
		and p.Data<'2014-05-26'