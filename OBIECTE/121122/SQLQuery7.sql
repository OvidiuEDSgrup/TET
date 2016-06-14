select bt.Pret*(1-25/100),round((bt.Total/8)/0.75,2),TVA/cantitate,* 
--update bt set cantitate=8,bt.pret=round((bt.Total/8)/0.75,2)
from bt where bt.Cod_produs='19PK-1605           '
select * from stocuri s where s.Cod='19PK-1605           ' and s.Cod_gestiune like '212%'
select dbo.wfListaGestiuniAtasatePV('212.1')