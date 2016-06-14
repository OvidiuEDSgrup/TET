SELECT * FROM pozincon p  where p.Data between '2012-09-01' and '2012-09-30' and p.Tip_document='AC'
--and '707.1' in (p.Cont_creditor)
--select CONVERT(decimal(17,2),5.32907051820075E-15)
select SUM(r.Rulaj_debit) from rulaje r where r.Data between '2012-09-01' and '2012-09-30'
and r.Cont like '707.0%'

select SUM(p.Suma) from pozplin p where p.Data between '2012-09-01' and '2012-09-30'
and (p.Cont_corespondent like '707%' or p.Cont_dif like '707%')

select distinct p.Tip_document,p.Cont_creditor,p.Cont_debitor 
from pozincon p where LEFT(p.Cont_creditor,3) like '707' or LEFT(p.Cont_debitor,3) like '707' 