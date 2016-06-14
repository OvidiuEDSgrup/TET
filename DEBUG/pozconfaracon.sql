select * 
-- delete p
from pozcon p where not exists
(select 1 from 	con where con.Subunitate=p.Subunitate and con.Tip=p.Tip and con.Contract=p.Contract and con.Data=p.Data and con.Tert=p.Tert)
and p.Subunitate='1'