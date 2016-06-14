select * from pozdoc p where '211.1' in (p.Gestiune,p.Gestiune_primitoare) and p.Cod='00202334'
and '' in (p.Cod_intrare,p.Grupa)

select * from sysspd s where s.Cod='00202334'
and s.Tip='AC' and s.Numar like '10001' and s.data='2012-07-12'