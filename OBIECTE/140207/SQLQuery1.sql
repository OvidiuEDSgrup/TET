SELECT * FROM con c where c.Tert='' order by c.Data desc
select i.tert
from infotert i where i.Subunitate like 'c%'
group by tert
having COUNT(distinct identificator)>1
order by COUNT(distinct identificator) desc