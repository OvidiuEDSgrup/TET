select * from sysspd s 
where (s.Contract='4052' or s.Factura='4052')
and s.Cod='UFH-ACT230NC2' 
order by s.Data_stergerii desc 
select * from pozdoc S
where 
--p.Numar='REZ00611'
(s.Contract='4052' or s.Factura='4052')
and s.Cod='UFH-ACT230NC2'

select * from sysspd s 
where s.Numar='4558' and s.Tip='TE'
--(s.Contract='4052' or s.Factura='4052')
--and s.Cod='UFH-ACT230NC2' 
order by s.Data_stergerii desc 