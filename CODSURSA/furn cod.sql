select furnizor,cod 
--into tempdb..temp_cod_furn7601       
from nomencl 
where 
--(furnizor = '10867728     ' or 1 = 0)
 (0 = 0 or (0=0 and categorie = 0) or (0=1 and categorie <> 0))
and furnizor<>''
union
Select tert as furnizor ,cod_resursa as cod  
from ppreturi 
where 1=1 and tip_resursa = 'C' 
--and (tert = '10867728     ' or 1 = 0)
and cod_resursa in (select cod from nomencl where  (0 = 0 or (0=0 and categorie = 0) or (0=1 and categorie <> 0)))
and tert<>''
