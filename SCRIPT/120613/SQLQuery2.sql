select * from docsters d
where d.Tip='AC' and d.Numar='30002' and d.Data='2012-06-13'

select d.Cod,d.Cod_intrare,* from pozdoc d
where d.Tip='AC' and d.Numar='30002' and d.Data='2012-06-13'
order by d.Cod,d.Cod_intrare

select d.Cod,d.Cod_intrare
--,* 
from pozdoc d
where d.Tip='AC' and d.Numar='30002' and d.Data='2012-06-13'
group by d.Cod,d.Cod_intrare
having COUNT(distinct d.Numar_pozitie)>1
--order by d.Cod,d.Cod_intrare

--sp_help docsters

select * from bp b where b.Tip='21' and b.Data='2012-06-13' and b.Casa_de_marcat=3 and b.Numar_bon=2
order by b.Cod_produs