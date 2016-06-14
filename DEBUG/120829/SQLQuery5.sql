select * from stocuri s where s.Cod_gestiune='213.1' and s.Cod like '100-ISO4-16-BL'
select * from pozdoc p where p.Tip='ac' and p.Data='2012-08-29' and p.Gestiune like '213%'
select * from pozdoc p where p.Tip='te' and p.Data='2012-08-29' and (p.Gestiune like '213%' or p.Gestiune_primitoare like '213%')