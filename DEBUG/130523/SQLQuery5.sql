
--delete yso_CodInl insert yso_CodInl (tip,Cod_nou,Cod_vechi)
select tip,Cod_nou,Cod_vechi
from testov..yso_CodInl c
--WHERE c.Cod_nou like '%tr_0%'
order by c.tip, c.Cod_nou,c.Cod_vechi