select SUM(r.Rulaj_debit)
from rulaje r inner join CalStd c on c.Data=r.Data
where r.cont like '607%' and r.Data=c.Data_lunii
EXPANDEZ({r.data},{r.Loc_de_munca})