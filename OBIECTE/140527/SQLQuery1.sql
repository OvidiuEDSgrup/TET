with s as (select top (1) * -- delete 
from sesiuniRIA s
order by s.activitate)
delete s