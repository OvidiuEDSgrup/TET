select 
(select sum(pa.cant_comandata) from pozaprov pa where pa.tip='N' and pa.comanda_livrare=na.numar and pa.data_comenzii=na.data and pa.beneficiar='' and pa.cod=na.cod)
,sum(na.Cantitate),'0', '01/01/2015', 'IT09076750158',
na.cod, 'N', na.numar, na.data, '', 
sum(na.cantitate)-isnull((select sum(pa.cant_comandata) from pozaprov pa 
where pa.tip='N' and pa.comanda_livrare=na.numar and pa.data_comenzii=na.data and pa.beneficiar='' and pa.cod=na.cod), 0) c, 
0, 0
from necesaraprov na
inner join nomencl n on na.cod = n.cod
where 1=1 and 2  in (0,2) and na.data between '01/01/2015' and '01/30/2015' and na.stare='1' and (1=0 or na.gestiune='101') 
and (0=0 or na.cod like RTrim(''))  and (charindex(','+rtrim(n.grupa)+',','') > 0 or 0 = 0)
group by na.numar, na.data, na.cod
select * from pozaprov