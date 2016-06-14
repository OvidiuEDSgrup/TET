select distinct p.Loc_de_munca
from pozincon p where p.Loc_de_munca<>'' 
and p.Loc_de_munca not in 
(select cod from tet..lm)
and p.Loc_de_munca not in 
(select c.cod_vechi from yso_CodInl c)
--order by p.Data_operarii desc
/*
select *--distinct p.Loc_de_munca
from pozdoc p where p.Loc_de_munca<>'' 
and p.Loc_de_munca not in 
(select cod from tet..lm)
and p.Loc_de_munca in 
(select c.Cod_vechi from yso_CodInl c)
order by p.Data_operarii desc
*/