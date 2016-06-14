select 
--SUM( c.stoc*pret)
--distinct cod
* 
from coduri_tbl_debug_tmp c --left join pozcon p on p.Contract='9820182' and p.Cod=c.cod
select 
--p.cod, MAX(n.denumire), SUM(p.Cant_aprobata)
--distinct cod
* 
from pozcon p left join nomencl n on n.cod=p.cod where p.Tip='BK' AND P.Contract='9820182'
--group by p.Cod having COUNT(*)>1

select --distinct cod
*
from stocuri s where s.Contract='9820182'