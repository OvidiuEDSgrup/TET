select * from stocuri s where s.Cod_intrare='' and ABS(s.Stoc)>0.001
order by data

select * from pozdoc p where p.Cod='RB-FY114' and '211' in (p.Gestiune,p.Gestiune_primitoare)
and '' in (p.Cod_intrare, p.Grupa)
--select * from no