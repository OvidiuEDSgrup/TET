set transaction isolation level read committed
begin tran
alter table pozdoc disable trigger all
--/*
select distinct p.Utilizator,p.Gestiune, r.gestimpl
--*/update p set Gestiune=r.gestimpl
from pozdoc p  join
(select distinct utilizator=r.Cod,gestimpl=max(r.Valoare)
from proprietati r where r.Tip='UTILIZATOR' and r.Cod_proprietate='GESTIUNEIMPLICITA' and r.Valoare<>'' and r.Valoare_tupla=''
group by r.Cod) r on r.utilizator=p.Utilizator
where p.Tip='AS'
alter table pozdoc enable trigger all
commit tran