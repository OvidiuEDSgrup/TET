select s.*,p.* from pozdoc p left join stocuri s on s.Cod_gestiune=p.Gestiune_primitoare and s.Cod=p.Cod and s.Cod_intrare=p.Grupa
where p.Numar='9320510'
