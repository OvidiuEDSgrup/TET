select * from yso_CodInl c where '1OFF07   ' in (c.Cod_nou,c.Cod_vechi)
-- delete yso_CodInl 
--insert yso_CodInl (Tip,Cod_nou,Cod_vechi)
select Tip,Cod_nou,Cod_vechi 
from testov..yso_CodInl
order by Tip,Cod_nou desc ,Cod_vechi desc