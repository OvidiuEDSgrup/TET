select p.Grupa,p.Cont_corespondent,p.lot,s.Lot,* from pozdoc p join stocuri s on s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare and s.Cod_gestiune=p.Gestiune
where p.Numar='1143323' and p.cod='065099'
--exec RefacereStocuri null,null,null,null,null,null