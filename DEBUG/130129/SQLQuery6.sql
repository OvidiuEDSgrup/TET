select pi.Loc_de_munca,sum(pi.suma) suma--, sum(pi.suma_valuta) suma_valuta, pi.Subunitate, pi.Data, pi.Cont_creditor
--into #pozincon_credit
from pozincon pi where 
	'5311' in (left(pi.Cont_debitor,4),left(pi.Cont_creditor,4)) and pi.data between '2013-01-01' and '2013-01-31' --and pi.Loc_de_munca='' 
		--exists (select 1 from POZPLIN p where pi.Subunitate=p.subunitate and pi.Data=p.data and p.cont in (pi.Cont_creditor,pi.Cont_debitor) and p.Cont='5311.2' and p.data between '2013-01-01' and '2013-01-31')
		--and (@lista_lm=0 or /*lu.cod is not null*/ exists (select * from LMFiltrare lu where lu.utilizator=@userASiS and lu.cod=pi.Loc_de_munca ))
group by pi.Loc_de_munca--pi.Subunitate, pi.Data, pi.Cont_creditor

select * from rulaje r where r.Cont like '5311.2' and r.Data between '2013-01-01' and '2013-01-31'
