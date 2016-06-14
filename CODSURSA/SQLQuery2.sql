select p.cod, max(n.denumire) as denumire_nomencl, max(n.furnizor) as furnizor_nomencl, 
sum(p.cantitate) as cantitate_comandata, 
isnull((select sum(s.stoc) from stocuri s where s.subunitate = p.subunitate and s.cod_gestiune = '101      ' and s.cod = p.cod), 0) as stoc_scriptic
from pozcon p inner join con c on p.subunitate = c.subunitate and p.tip = c.tip and p.contract = c.contract and p.data = c.data and p.tert = c.tert 
inner join nomencl n on p.cod = n.cod 
where p.subunitate = '1        ' and p.tip = 'BK' and c.stare = '0' 
/*and (RTrim(p.mod_de_plata)<='1901/01/01' or p.zi_scadenta_din_luna>0)*/ and p.factura = '101      ' 
and (0 = 0 or charindex(';' + rtrim(p.punct_livrare) + ';', ';;') > 0) 
and (0 = 0 or charindex(';' + rtrim(n.grupa) + ';', ';;') > 0) 
and (0 = 0 or charindex(';' + rtrim(p.contract) + ';', ';;') > 0) 
and (0 = 0 or charindex(';' + rtrim(c.loc_de_munca) + ';', ';;') > 0) 
and (0 = 0 or charindex(';' + rtrim(n.furnizor) + ';', ';;') > 0) 
group by p.subunitate, p.cod
