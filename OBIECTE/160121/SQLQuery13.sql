--select * from pozdoc p where p.Tip ='RM' and p.Numar like '1142%' and p.Data>='2016-01-15'

select p.Cont_corespondent,p.Grupa,p.Cod_intrare,* 
from sysspd p where p.Tip='RM' AND p.Numar like '1142964' and p.Cod like '06625301'
order by p.Data_stergerii desc