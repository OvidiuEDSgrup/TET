
exec wDescarcBon '','<row idAntetBon="2274" />'
select * from bt
select * -- delete
from pozdoc p where p.Contract='9812485'
select * from pozdoc p where p.Numar='9411348'

select * from sysspd p where p.Contract='9812485'
select * from sysspd p where p.Numar='9411348'
select * from sysspd p where abs(datediff(mi,p.Data_stergerii,'2013-07-06 08:12:09.910'))<=45
select * from sysspcon p where abs(datediff(mi,p.Data_stergerii,'2013-07-06 08:12:09.910'))<=5
select * from sysspcon p where p.Contract='9812485'
select * from pozcon p where p.Contract='9812485'
select n.Denumire,p.* from sysspd p inner join nomencl n on  n.Cod=p.Cod
where abs(datediff(mi,p.Data_stergerii,'2013-07-05 17:09:28.000'))<=25

select * from yso_sysspd_antet a where a.Data_operatiei in 
(select distinct p.Data_stergerii from sysspd p where p.Numar='9411348')
--('2013-07-05 17:09:28.750','2013-07-05 17:09:28.783')

select * from webJurnalOperatii j 
where j.data<='2013-07-05 08:05:00.000'--,'2013-07-05 17:09:28.783'
--where j.parametruXML.value( '(/*/@numar)[1]','varchar(20)')='9812485'
--where j.obiectSql like 'wDescarcBon%'
order by j.data desc

select * from pozdoc p where p.Subunitate='1' and p.Cantitate<=-0.001 and p.Pret_de_stoc=p.Pret_vanzare
order by p.Data_operarii desc,p.Ora_operarii desc
select * from docfiscalerezervate