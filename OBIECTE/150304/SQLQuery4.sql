select * -- delete j
from JurnalContracte j where j.utilizator='asis'

--select * -- update j set stare=stare-1
--from JurnalContracte j join Contracte c on c.idContract=j.idContract and c.tip='RN' 

select distinct stare from StariContracte