select c.* -- update p set mod_de_plata='20140315'
from pozcon p join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Data=p.Data and c.Tert=p.Tert
where c.Contract='15884'