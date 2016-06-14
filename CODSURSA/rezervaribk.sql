select distinct c.tert, c.contract, c.data 
from stocuri s, con c
where s.subunitate=':1' and s.tip_gestiune not in ('F', 'T') 
and charindex(';'+RTrim(s.cod_gestiune)+';', ';'+RTrim(':2')+';')>0 
and s.stoc >= 0.001 and s.contract <> ''
and s.contract = c.contract and s.subunitate = c.subunitate and c.tip='BK' 
and (rtrim(':3') = '' or c.tert = ':3') and (rtrim(':4') = '' or c.contract = ':4')


select p.numar, s.data, s.cod_gestiune, sum(s.stoc) as cantitate, s.cod, max(n.denumire) as denumire 
from stocuri s, pozdoc p, nomencl n
where s.subunitate = ':1' and s.tip_gestiune not in ('F', 'T') 
and charindex(';'+RTrim(s.cod_gestiune)+';', ';'+RTrim(':2')+';')>0
and s.contract=':3' and s.stoc >= 0.001 
and (':4' = '' or s.cod = ':4') 
and p.subunitate = s.subunitate and p.tip='TE' and p.data = s.data and p.cod = s.cod 
and p.gestiune_primitoare = s.cod_gestiune and p.factura = s.contract and p.grupa = s.cod_intrare 
and p.stare not in ('4', '6') and p.cantitate>0
and n.cod = s.cod
group by s.cod_gestiune, s.cod, s.data, p.numar
order by s.data DESC, p.numar DESC, s.cod

Subunitate, Tip_gestiune, Cod_gestiune, Cod, Cod_intrare


select distinct cod 
from stocuri 
where subunitate=':1' and tip_gestiune not in ('F', 'T') 
and charindex(';'+RTrim(cod_gestiune)+';',';'+RTrim(':2')+';')>0 
and contract=':3' and stoc>=0.001
