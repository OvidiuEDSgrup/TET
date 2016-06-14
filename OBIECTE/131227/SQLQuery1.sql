select p.Gestiune,p.Gestiune_primitoare,p.Cod_intrare,p.Grupa,* from pozdoc p where p.Cod='0066003' and '6064015A' in (p.Cod_intrare,p.Grupa)
order by p.Data

select * from con c where c.Gestiune='101' and c.Cod_dobanda like '400%'
select * from con c where c.Gestiune like '211%' and c.Cod_dobanda like '400%'
order by c.Data

select * from con c where c.Gestiune like '211%' and c.Cod_dobanda like '101%'
order by c.Data

select * from con c where c.Gestiune='101' and c.Cod_dobanda like '211%'