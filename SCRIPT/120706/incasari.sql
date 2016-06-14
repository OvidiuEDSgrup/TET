select  
'incasari'
,pp.Loc_de_munca
--,pp.cont
,pp.data
--,pp.Numar
,sum(pp.Suma) suma
--,sum(pp.Suma/1.24)
,SUM(pp.TVA22) TVA
,sum(pp.Suma-PP.TVA22) suma_fara_tva
from pozplin pp 
where 
pp.Plata_incasare='IC' 
and left(pp.Cont_corespondent,3) in ('707','706','704')
and left(pp.Cont,4) in ('5311','5113')
and pp.Data between '2012-06-01' and '2012-06-30'
--and pp.Data='2012-06-26'
and pp.Loc_de_munca='1mkt19'
group by 
----pp.Cont
pp.Loc_de_munca
,pp.data
--,pp.Numar