select * --update e set subunitate='0'
from efecte e where e.Tert like '%30234682%'

SELECT * FROM yso_TabInl T where t.Denumire_SQL like 'efecte'

if exists (select * from sysobjects where name = 'plinefect' and xtype='TR') alter table pozplin enable trigger plinefect