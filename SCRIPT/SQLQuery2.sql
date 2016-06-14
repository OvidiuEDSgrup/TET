select p.Cod,SUM(d.Cantitate), max(p.Cant_aprobata)
from pozcon p inner join con c on c.Tip=p.Tip and c.Contract=p.Contract
left join pozdoc d on d.Tip='TE' and d.Factura=p.Contract and d.Cod=p.Cod
where p.Subunitate='1' and p.Tert='2810824124246' 
and p.Contract='9820293'
group by p.Cod
--having SUM(d.Cantitate)<>max(p.Cantitate)

select COUNT(distinct cod) from pozcon p where p.Contract='9820293' and p.Subunitate='1'
select COUNT(distinct cod) from pozdoc d where d.Numar='9320201'