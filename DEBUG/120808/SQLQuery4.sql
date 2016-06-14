select c.* from pozdoc t left join pozcon c on c.subunitate=t.subunitate and c.tip='BK' and c.Contract=t.factura 
and t.Comanda=c.Tert and t.Cod=c.Cod
where t.Numar='9320218'

select * from pozdoc t where t.Numar like '9320218'

select * from pozcon c where c.Contract='9820302' and c.Subunitate='1'

select * from sysspcon s where s.Contract='9820302'
order by s.data_stergerii desc

select * from sysscon s where s.Contract='9820302'
order by s.data_stergerii desc