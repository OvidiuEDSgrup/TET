select * -- update t set judet=s.judet
from terti t cross apply
(select top 1 * from sysst s where s.Judet<>'' and s.Tert=t.Tert
order by s.Data_stergerii desc) s
where t.Judet='' and s.Judet<>t.Judet

