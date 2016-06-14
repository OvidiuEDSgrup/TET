
select  
'bonuri'
,a.Loc_de_munca
,a.Data_bon
--,a.Numar_bon
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
where bp.Tip='21' and bp.Factura_chitanta=1
and bp.Data between '2012-06-01' and '2012-06-30'
--and bp.Data='2012-06-26'
--and bp.Casa_de_marcat*20000+bp.Numar_bon='20001'
--and bp.Casa_de_marcat=2 and bp.Numar_bon=1
--and bp.Cod_produs='100-ISO4-R16-RO'
AND bp.Cod_produs<>'AVANS'
and a.Loc_de_munca='1mkt19'
group by a.Loc_de_munca
,a.Data_bon
--,a.Numar_bon
--order by bp.Cod_produs
