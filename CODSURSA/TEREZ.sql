select p.numar, s.data, s.cod_gestiune, sum(s.stoc) as cantitate, s.cod, max(n.denumire) as denumire ,s.data,p.numar,s.cod
 from stocuri s, pozdoc p, nomencl n
where s.subunitate = '1        ' and s.tip_gestiune not in ('F', 'T') 
and charindex(';'+RTrim(s.cod_gestiune)+';', ';'+RTrim('300;900                                                                                                                                                                                                 ')+';')>0
and s.contract='1031538             ' and s.stoc >= 0.001 
and ('                    ' = '' or s.cod = '                    ') 
and p.subunitate = s.subunitate and p.tip='TE' and p.data = s.data and p.cod = s.cod 
and p.gestiune_primitoare = s.cod_gestiune and p.factura = s.contract and p.grupa = s.cod_intrare 
and p.stare not in ('4', '6') and p.cantitate>0
and n.cod = s.cod
group by s.cod_gestiune, s.cod, s.data, p.numar
--select * from stocuri
--where Contract='1031538'
