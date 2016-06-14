select * from pozdoc p  where p.Tip='AC' and p.Cod='4300902006021       ' and p.Data='2012-07-13'
select * from pozdoc p where p.Cod='4300902006021       ' and 'IMPL1AA' in (p.Cod_intrare,p.Grupa) 
and '211.1' in (p.Gestiune,p.Gestiune_primitoare)
select * from pozdoc p where p.Cod='4300902006021       ' and 'IMPL1AAA' in (p.Cod_intrare,p.Grupa) 
and '211' in (p.Gestiune,p.Gestiune_primitoare)
