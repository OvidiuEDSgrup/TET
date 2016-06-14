select distinct pd.Factura,pd.Gestiune,pd.Loc_de_munca,pd.Numar,s.Loc_de_munca, c.Loc_de_munca, n.Gestiune,s.Stoc
--,s.* 
from stocuri s cross apply (select * from pozdoc p where p.Subunitate='1' and p.Tip='TE' 
and p.Gestiune_primitoare=s.Cod_gestiune and p.Cod=s.Cod and p.Grupa=s.Cod_intrare) pd
left join comenzi c on c.Comanda=s.Comanda
left join con n on c.Subunitate=s.Subunitate and n.Tip='BK' and n.Contract=s.Contract and n.Contract<>''
where  s.Cod_gestiune='700' --and n.Gestiune='213'