select n.Pret_stoc,p.Contract,* from pozdoc p inner join nomencl n on n.Cod=p.Cod left join stocuri s on s.Cod=p.Cod and s.Cod_gestiune=p.Gestiune and s.Cod_intrare=p.Cod_intrare
where p.Tip='AP' and p.Valuta<>'' and p.Discount<>0
--and p.Pret_de_stoc=p.Pret_vanzare 
order by p.Data desc