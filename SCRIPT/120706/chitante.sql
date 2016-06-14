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
--,p.Loc_de_munca
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
and p.Loc_de_munca='1mkt19'
--and p.Numar like '20001'
--and p.Cod like '100-ISO4-R16-RO'
--and p.Cod like 'AVANS%'
--group by p.Loc_de_munca
--,p.Data