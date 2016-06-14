select * -- delete a
-- update a set factura=''
from antetBonuri a where a.Factura like 'FS%' and a.Tert like '.%' --and a.Numar_bon<0
order by a.IdAntetBon desc, a.Factura desc