select * from bt bp where bp.Data='2012-07-13' and bp.Cod_produs like '5092%'

select * from stocuri s where s.Cod like '5092 018000000' 
and s.Cod_gestiune like '212%'
select * from pozdoc p where p.Tip='te' and p.Data='2012-07-13' and p.Cod like '5092 018000000' 

select * from bp 
where bp.Data='2012-07-13' and bp.Cantitate<0

select * from pozdoc p where p.Tip='te' and p.Data='2012-07-13' and p.Cod like '4300902006021' 
select * from stocuri s where s.Cod like '4300902006021' and s.Cod_gestiune like '211%'

select * from pozdoc p
where p.Cod like '5092 018000000'
and '212.1' in (p.Gestiune,p.Gestiune_primitoare)
and '' in (p.Cod_intrare,p.Grupa)