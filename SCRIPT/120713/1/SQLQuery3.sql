select * from bt where bt.Cod_produs='5092 018000000'
select * from nomencl n where n.Cod='5092 018000000'
select * 
--delete s
from stocuri s where s.Cod='5092 018000000' and s.Cod_gestiune like '211%' 
and s.Pret_cu_amanuntul=2.24