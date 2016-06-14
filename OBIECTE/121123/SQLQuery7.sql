select * from sysspcon p where p.Contract='9830438'
select * from pozcon p where p.Contract='9830438'
select SUM(sold),SUM(sold)+1592.25  from facturi f where f.Tert='19119704' and f.Sold>=0.001
select SUM(sold)  from efecte f where f.Tert='19119704'