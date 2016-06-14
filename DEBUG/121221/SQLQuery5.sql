select * from pozdoc p where p.Cod='510842' and '211.1' in (p.Gestiune,p.Gestiune_primitoare)
and '5890005EA' in (p.Cod_intrare,p.Grupa)