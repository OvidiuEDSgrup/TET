select 
'chitante'
--p.Cod
--,p.Cantitate
--,p.Pret_cu_amanuntul
--,p.Pret_amanunt_predator
--,p.Pret_vanzare
--,p.Cantitate*p.Pret_vanzare as val_vanzare
--,p.Pret_valuta
--,p.Discount
----,p.Cantitate*p.Pret_valuta-(p.Pret_valuta*p.Discount/100) as val_vanzare_lista
--,p.Cantitate*(p.Pret_amanunt_predator/1.24)*(1-p.Discount/100) as val_vanzare_am_pred
--,*
,p.Loc_de_munca
--,p.Data
--distinct p.Cont_venituri
--p.Pret_amanunt_predator,*
--,SUM(p.Cantitate*case p.tip when 'ac' then p.Pret_amanunt_predator else p.Pret_vanzare end) pret_amanunt_pred
,SUM(p.Cantitate*p.Pret_vanzare) pret_vanzare
,SUM(p.Cantitate*p.Pret_valuta-(p.Pret_valuta*p.Discount/100)) pret_lista
,SUM(p.Cantitate*(p.Pret_amanunt_predator/1.24)*(1-p.Discount/100)) pret_am_pred
from pozdoc p where p.Tip in (/*'AP'*/'AC')
and p.Cont_venituri like '7%'
and p.Data between '2012-06-01' and '2012-06-30'
--and p.Loc_de_munca='1mkt20'
--and p.Numar like '20001'
--and p.Cod like '100-ISO4-R16-RO'
--and p.Cod like 'AVANS%'
group by p.Loc_de_munca
--,p.Data


select  
'bonuri'
,a.Loc_de_munca
--,a.Data_bon
--bp.l,bp.Data
,sum(bp.Total-bp.Tva) total_fara_tva
--bp.Cod_produs
--,bp.Cantitate,bp.Pret
--,bp.Pret*bp.Cantitate as val
--,bp.Tva as tva
--,bp.Pret*bp.Cantitate-bp.Tva as valftva
--,*
--SUM(bp.Pret*bp.Cantitate) val
--,sum(bp.Tva) tva
from bp inner join antetBonuri a on a.IdAntetBon=bp.IdAntetBon
where bp.Tip='21' 
and bp.Data between '2012-06-01' and '2012-06-30'
--and bp.Casa_de_marcat*20000+bp.Numar_bon='20001'
--and bp.Casa_de_marcat=2 and bp.Numar_bon=1
--and bp.Cod_produs='100-ISO4-R16-RO'
group by a.Loc_de_munca
--,a.Data_bon
--order by bp.Cod_produs

select  
'incasari'
,pp.Loc_de_munca
--,pp.data
--,pp.Numar
,sum(pp.Suma-PP.TVA22) suma_fara_tva
from pozplin pp 
where 
--pp.Plata_incasare='IC' 
pp.Cont_corespondent like '707%'
and left(pp.Cont,4) in ('5311','5113')
and pp.Cont_corespondent like '7%'
and pp.Data between '2012-06-01' and '2012-06-30'
--and pp.Cont='5311.4'
--and pp.Loc_de_munca='1mkt20'
group by pp.Loc_de_munca
--,pp.data