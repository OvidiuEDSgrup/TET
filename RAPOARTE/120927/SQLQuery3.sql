select * from istoricstocuri i left join stocuri s 
on s.Subunitate=i.Subunitate and s.Tip_gestiune=i.Tip_gestiune and s.Cod_gestiune=i.Cod_gestiune
and s.Cod=i.Cod and s.Cod_intrare=i.Cod_intrare
where s.Data is null and 