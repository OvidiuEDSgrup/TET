begin tran
update necesaraprov
set stare='1'
from necesaraprov n, tmpselectie t
where t.terminal='7092    ' and t.cod=n.numar+convert(char(10), n.data, 101)+str(n.numar_pozitie, 9)
and t.selectie=1 and n.stare='0'

rollback tran