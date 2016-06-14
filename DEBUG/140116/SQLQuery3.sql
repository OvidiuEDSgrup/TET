select distinct p.Loc_de_munca,data from pozplin p where p.Cont like '5311.ag' --order by data desc
select * from rulaje r where r.Cont like '5311.ag' order by r.Data desc
select * from pozincon p where '5311.ag' in (p.Cont_debitor,p.Cont_debitor) and p.Data between '2014-01-01' and '2014-01-06'