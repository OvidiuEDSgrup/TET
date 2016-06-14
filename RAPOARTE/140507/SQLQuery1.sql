select * 
from dbo.fFacturi ('F', '2013-01-01', '2013-12-31', null, '%', null, 0, 0, 0, null,null) p
where '472' in (p.contTVA,p.cont_coresp,p.cont_de_tert)