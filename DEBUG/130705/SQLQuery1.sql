select * from anexafac a where a.Numele_delegatului<>''
a.Numar_factura like '9411347'
select * from anexadoc a where a.Numar like '9440125'
select * from pozdoc a where a.Factura like '9440125'
select * from sysspd a where a.Factura like '9440125'
select * from yso_sysspd_antet s where s.Data_operatiei='2013-07-05 08:25:07.793'

select top 5000 * from webJurnalOperatii w order by w.data desc
where w.obiectSql like '%BK%'

select * from pozdoc p where p.Numar like '9411347'
select * from pozdoc p where p.Contract like '9812143'