select * from stocuri s where s.Cod='tvhp' and s.Cod_gestiune='211.is' 
select * from pozdoc p where p.Cod='tvhp' and '211.is' in (p.Gestiune,p.Gestiune_primitoare) and '1140443008A' in (p.Cod_intrare,p.Grupa) 
order by p.Data

select * from pozdoc p where p.Cod='tvhp' and '101' in (p.Gestiune,p.Gestiune_primitoare) and '1140443008A' in (p.Cod_intrare,p.Grupa) 
order by p.Data

select * from pozdoc p where p.Cod='tvhp' and '101' in (p.Gestiune,p.Gestiune_primitoare) and '1140443008' in (p.Cod_intrare,p.Grupa) 
order by p.Data

select p.Contract,p.Factura,* from pozdoc p where p.Numar='AG940148'
select * from con c where c.Contract like 'AG98032[01]'
select p.Factura,* -- DELETE p
from pozdoc p where p.Contract like 'AG980320            '
select p.Factura,* from doc p where p.Contractul like 'AG980320            '

select a.Bon,* from antetBonuri a where a.Data_bon='2014-06-19'