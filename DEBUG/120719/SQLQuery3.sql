select n.Denumire,bp.* from bp inner join nomencl n on n.Cod=bp.Cod_produs
where bp.Data='2012-07-18' and bp.Casa_de_marcat=2

select * from stocuri s where s.Cod='1507CU3'
and s.Cod_gestiune like '212%' 

select * from pozdoc p where p.Tip in ('AC','TE') and p.Cod='1507CU3' 
and p.Data between '2012-07-18' and '2012-07-19' --and p.Numar like left(RTRIM(2*10000),4)+'%'--[1-2]'
order by p.Numar,p.Tip desc

select distinct s.Pret_cu_amanuntul from stocuri s where s.Tip_gestiune='a'