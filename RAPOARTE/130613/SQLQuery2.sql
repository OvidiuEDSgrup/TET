select datediff(m,'2012-02-13 00:00:00.000','2013-03-21 00:00:00.000')

select * from pozdoc p where p.Tip='PP' and p.Cod like 'PKSONEP150_11       '
order by p.Data
select * from pozdoc p where p.Tip in ('ap','ac')
and p.Cod_intrare='19/03001A           '
and p.Cod='PKSONEP150_11'

select p.Cod_intrare,d.Cod_intrare,d.Grupa,* from pozdoc d
inner join (select p.Cod,p.Gestiune,p.Cod_intrare,nr=COUNT(distinct p.Data)
from pozdoc p where p.Subunitate='1' and p.Tip='PP' 
group by p.Cod,p.Gestiune,p.Cod_intrare
having COUNT(distinct p.Data)>1) p on p.Cod=d.Cod and p.Gestiune in (d.Gestiune,d.Gestiune_primitoare)
and p.Cod_intrare in (d.Cod_intrare,d.Grupa)
order by d.Data, d.Tip desc