select * from proprietati p where p.Cod='100585RO            '
select * from valproprietati v where v.Cod_proprietate='areserii'
--sp_helptrigger proprietati

select * --update p set valoare=(case valoare when '1' then 'DA' when '0' then 'NU' end)
from proprietati p where p.Cod_proprietate='ARESERII' and p.Valoare in ('0','1')