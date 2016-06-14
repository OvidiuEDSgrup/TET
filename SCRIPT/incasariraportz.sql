select p.Loc_de_munca,p.data,left(p.Cont_corespondent,3) Cont
,SUM(p.Suma-p.tva22) valoare
into ##incasari
from pozplin p where p.Data between '2012-09-01' and '2012-09-30'
and left(p.Cont_corespondent,3) in ('707','472') 
group by p.Loc_de_munca,p.Data,p.Cont_corespondent
--with rollup
order by p.Loc_de_munca,p.Data

--SELECT SUM(p.Suma) from pozincon p where p.Tip_document='pi'
----and p.Explicatii like 'ic%'
--and p.Cont_creditor like '707%' 
--and p.Data between '2012-09-01' and '2012-09-30'
----order by p.Loc_de_munca,p.Data