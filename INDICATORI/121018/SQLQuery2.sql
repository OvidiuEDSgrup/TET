select * from rulaje r where LEFT(r.Cont,3) in ('607','371') and r.Data between '2012-08-01' and '2012-08-31'
order by r.Data

select * from Expval e where e.Cod_indicator in ('RCD607','SCD371')