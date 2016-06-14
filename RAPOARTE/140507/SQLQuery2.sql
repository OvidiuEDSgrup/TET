select p.Tert,*
from pozdoc p join conturi c on c.Cont=p.Cont_de_stoc and c.Sold_credit=2
order by p.Data desc