select * from stocuri s join pozdoc p on p.Subunitate=s.Subunitate and p.Cod=s.Cod and p.Gestiune=s.Cod_gestiune and p.Cod_intrare=s.Cod_intrare
where s.Cod_gestiune='101' --and s.Contract<>''
and p.Numar='1143193'