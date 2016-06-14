select * from rulaje r 
where r.Data='2014-01-01'
and r.Loc_de_munca=''
and r.Cont like '5311%'
select p.Loc_de_munca,* from pozincon p where '5311.nt' in (p.Cont_creditor,p.Cont_debitor)
and p.Data between '2013-12-01' and '2013-12-31'