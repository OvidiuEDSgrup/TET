select r.Rulaj_credit,r.Rulaj_debit from testov..rulaje r where r.Data<='2012-01-31' and r.Cont like '442%'
except
select r.Rulaj_credit,r.Rulaj_debit from rulaje r where r.Data<='2012-01-31' and r.Cont like '442%'
