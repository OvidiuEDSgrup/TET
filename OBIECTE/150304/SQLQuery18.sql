select * -- delete j
-- update j set stare=-15
from JurnalContracte j join Contracte c on c.idContract=j.idContract
where c.tip='RN' 
and stare>0