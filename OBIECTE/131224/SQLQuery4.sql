alter table pozdoc disable trigger all
alter table doc disable trigger all
--select * 
update p set Gestiune=''
from pozdoc p where p.Subunitate='1' and p.Tip='AS' and p.Gestiune <> ''
update p set Cod_gestiune=''
--select * 
from doc p where p.Subunitate='1' and p.Tip='AS' and p.Cod_gestiune <> ''
alter table pozdoc enable trigger all
alter table doc enable trigger all