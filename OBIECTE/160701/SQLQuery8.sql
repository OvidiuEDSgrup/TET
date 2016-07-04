select p.Contract,*
from pozdoc p join stocuri s on s.Subunitate=p.Subunitate and s.Cod_gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
join pozaprov a on a.Contract=p.Contract and a.Furnizor=p.Tert and a.Cod=p.Cod and a.Tip='N'
where p.Subunitate='1' and p.Tip='RM' and p.Data>='2016-01-01' and p.Contract<>''
and s.Stoc>0
order by p.idPozDoc desc