--insert par select 'GE','FARA44','',1,0,''
select * 
-- delete par
from par where tip_parametru='GE' and parametru='FARA44'
select case when val_logica=1 and val_numerica=0 then 1 else 0 end 
,*from par where tip_parametru='GE' and parametru='DOCPESCH'