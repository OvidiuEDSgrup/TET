select * 
from pozcon c inner join pozdoc p on p.Tip='AP' and p.Tert=c.Tert and p.Contract=c.Contract and p.Cod=c.Cod
where c.Contract='9850036'