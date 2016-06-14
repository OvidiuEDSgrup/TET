select p.Valoare
			,COUNT(distinct p.Cod)
-- select *
from proprietati p where p.Tip='UTILIZATOR' AND p.Cod_proprietate='LOCMUNCA' and p.Valoare_tupla=''
			and p.Valoare<>'' and p.Valoare='1MKT20'
			group by p.Valoare
			having COUNT(distinct p.Cod)>1