select * from pozdoc p join nomencl n on n.Cod=p.cod join tehnpoz tp on tp.Cod=n.Cod
--join tehn t on t.Cod_tehn=tp.Cod_tehn
join pozcon pc on pc.Cod=tp.Cod_tehn and p.Factura=pc.Contract
where p.Tip='TE' and  p.Gestiune_primitoare='300' 