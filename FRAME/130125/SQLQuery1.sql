--alter table pozincon disable trigger tr_validpozincon
select * -- update p set p.val_logica=0
from par p where p.Parametru='FARAVSTN'