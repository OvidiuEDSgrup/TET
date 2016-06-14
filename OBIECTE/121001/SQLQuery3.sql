select LEFT(p.idPozDoc,13),p.Gestiune_primitoare,p.Grupa,*
-- update p set cod_intrare=LEFT(p.idPozDoc,13)
from pozdoc p inner join nomencl n on n.Cod=p.Cod
where p.Tip_miscare='E' 
and p.Cod_intrare='' --or p.Grupa='' and p.Tip='te')
and p.Cod<>''
and n.Tip not in ('R', 'S', 'F')
and p.Data>='2012-09-01'
--and p.Cantitate<0
--and exists 
--(select 1 from stocuri s where s.Subunitate=p.Subunitate and s.Cod_gestiune in (p.Gestiune,p.Gestiune_primitoare)
--and s.Cod=p.Cod and s.Cod_intrare<>'' and s.Stoc>=0.001 and s.Data<=dbo.EOM(p.Data))
order by p.Data

select * from pozdoc p where p.Cod='25-ISO4-32-RO       ' and p.Data='2012-09-28'