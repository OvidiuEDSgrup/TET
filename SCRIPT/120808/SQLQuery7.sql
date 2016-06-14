select * from stocuri s where s.Cod like '2207cu3' and s.Cod_gestiune='700' and s.Comanda='1710605126190'
--select * from comenzi c where c.Descriere like '%moldovan%'
select * from pozdoc t where t.Tip='TE' and t.Gestiune_primitoare='700' and t.Comanda='1710605126190' and t.Cod like '2207cu3'
--select * from pozdoc p  where '5062001AAAA.' in (p.Cod_intrare,p.Grupa)