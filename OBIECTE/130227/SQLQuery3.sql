select * from testov..rulaje r 
where r.Data<='2012-01-01' --and r.Cont like '4428%'
ORDER BY r.Cont
--order by r.data,r.Rulaj_credit, r.Rulaj_debit