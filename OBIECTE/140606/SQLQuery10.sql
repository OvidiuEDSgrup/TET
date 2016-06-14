select n.Denumire,* from stocuri s join nomencl n on n.Cod=s.Cod
where s.Cod='tvhp' and s.Cod_intrare='6577008a' and s.Cod_gestiune='101'

select * from pozdoc s 
where s.Cod='tvhp' and s.Cod_intrare='6577008a' and s.Gestiune='101'