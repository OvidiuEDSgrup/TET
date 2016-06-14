select distinct a.Gestiune from antetbonuri a

select gestiune,data,SUM(round(round(cantitate*Pret_vanzare,2) + TVA_deductibil,2)) as val, SUM(cantitate) as cantitate
--into #ac
from pozdoc
where Subunitate='1' and tip='AC' 
and data between '2012-08-01' and '2012-08-31'
--and gestiune in ('211.1','212.1','213.1')
group by gestiune,data