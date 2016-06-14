select * from sysspcon p where p.Contract like '9813566' and p.Cod like '4300102000121'
select * from pozcon p where p.Contract like '9813566' and p.Cod like '4300102000121'
select top 100 * from webJurnalOperatii j where j.obiectSql like '%scriupozcon%'
order by j.data desc