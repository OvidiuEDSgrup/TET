CREATE view calcurseuro as  
select 'EUR' as valuta,c.data,
(select top 1 curs from curs where valuta='EUR' and data<=c.data order by data desc) as curs 
from calstd c 
union all  
select 'RON' as valuta,c.data,1 from calstd c  


