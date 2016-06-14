select * from stocuri s cross apply
(select * from pozdoc p where '12171' in (p.Contract,p.Factura)
and s.Cod_gestiune in (p.Gestiune,p.Gestiune_primitoare) and s.Cod=p.Cod and s.Cod_intrare in (p.Cod_intrare,p.Grupa)) p
where s.Stoc<0
select * from stocuri s where s.Contract='12171'
