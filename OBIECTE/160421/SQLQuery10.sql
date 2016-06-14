--select * -- update t set tipmachetanoua='E'
--from syssWebConfigTaburi t where t.NumeTab like '%doc%stor%' 
--order by t.data_modificarii desc
--select * -- update t set tipmachetanoua='E'
--from syssWebConfigTaburi t where t.NumeTab like '%FUND%COM%' 
--order by t.data_modificarii desc
select * -- update t set tipmachetanoua='C'
from webConfigTaburi t where t.NumeTab like '%doc%stor%'
select * -- update t set tipmachetanoua='C'
from webConfigTaburi t where t.NumeTab like '%fund%com%'

select * -- update t set tipmachetanoua='C'
from webConfigTaburi t where t.NumeTab like '%DOC%COM%'

select * -- UPDATE M SET TIPMACHETA='C'
from webConfigMeniu m where m.Meniu like 'DO_STORNO'
select * -- UPDATE M SET TIPMACHETA='C'
from webConfigMeniu m where m.Meniu like 'YSO_FA'
select * -- UPDATE M SET TIPMACHETA='C'
from webConfigMeniu m where m.Meniu like 'RA'

