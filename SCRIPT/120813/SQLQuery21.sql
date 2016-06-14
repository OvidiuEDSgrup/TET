--/*
select * 
--*/delete p
from pozcon p where p.Subunitate like 'EXPAND%' and p.Tip IN ('BK','BF') and p.Pret+p.Cantitate<0.001