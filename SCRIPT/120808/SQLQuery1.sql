--/*
update p set
--*/select *,
Comanda=c.Tert  
from pozdoc p inner join pozcon c on c.Subunitate=p.Subunitate and c.Tip='BK' and c.Contract=p.Factura and c.Cod=p.Cod
where p.Tip='TE' and p.Gestiune_primitoare='700'
and p.Comanda='' and p.Factura<>'' and c.Tert<>''