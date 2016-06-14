select * 
-- update pozcon set tert='RO6610440CJ',punct_livrare=''
from pozcon p where p.contract='9820271'

select * from sysscon s where s.contract='9820271'
order by s.Data_stergerii desc