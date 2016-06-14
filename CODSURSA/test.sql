

SELECT p.cod, 'BK', p.contract, p.data, p.tert, 
sum(p.cant_aprobata)-sum(CASE WHEN p.cant_realizata>=p.Pret_promotional THEN p.Cant_realizata ELSE p.Pret_promotional END)
	-isnull((select sum(cant_comandata) from pozaprov pa where pa.tip='BK' and pa.comanda_livrare=p.contract 
	and pa.data_comenzii=p.data and pa.beneficiar=p.tert and pa.cod=p.cod and abs(pa.cant_realizata)<0.001), 0), 
0, 0
from con c inner join pozcon p on c.subunitate=p.subunitate and c.tip=p.tip and c.contract=p.contract and c.data=p.data and c.tert=p.tert
inner join nomencl n on p.cod=n.cod
inner join tempdb..temp_cod_furn5604 pp on pp.cod = n.cod 
where c.subunitate='1' 
and n.tip in ('A', 'M') and p.tip='BK' and (c.stare = '1' or c.stare='0' and p.UM='1')
--and (0=0 or p.factura='101') 
--and (0=0 or n.cod like RTrim('')) 
and p.cant_aprobata-(CASE WHEN p.cant_realizata>=p.Pret_promotional THEN p.Cant_realizata ELSE p.Pret_promotional END)>=0.001 
--and (0=0 or p.termen between @dData and @dData)
--and (charindex(','+rtrim(n.grupa)+',','') > 0 or 0 = 0)
group by p.contract, p.data, p.tert, p.cod

SELECT p.cod, 'BK', p.contract, p.data, p.tert, 
p.cant_aprobata,p.cant_realizata,p.Pret_promotional,
isnull((select sum(cant_comandata) from pozaprov pa where pa.tip='BK' and pa.comanda_livrare=p.contract 
	and pa.data_comenzii=p.data and pa.beneficiar=p.tert and pa.cod=p.cod and abs(pa.cant_realizata)<0.001), 0) as comandat,
/*sum(p.cant_aprobata)-sum(CASE WHEN p.cant_realizata>=p.Pret_promotional THEN p.Cant_realizata ELSE p.Pret_promotional END)
	-isnull((select sum(cant_comandata) from pozaprov pa where pa.tip='BK' and pa.comanda_livrare=p.contract 
	and pa.data_comenzii=p.data and pa.beneficiar=p.tert and pa.cod=p.cod and abs(pa.cant_realizata)<0.001), 0), */
0, 0
from con c inner join pozcon p on c.subunitate=p.subunitate and c.tip=p.tip and c.contract=p.contract and c.data=p.data and c.tert=p.tert
inner join nomencl n on p.cod=n.cod
inner join tempdb..temp_cod_furn5604 pp on pp.cod = n.cod 
where c.subunitate='1' 
and n.tip in ('A', 'M') and p.tip='BK' and (c.stare = '1' or c.stare='0' and p.UM='1')
--and (0=0 or p.factura='101') 
--and (0=0 or n.cod like RTrim('')) 
and p.cant_aprobata-(CASE WHEN p.cant_realizata>=p.Pret_promotional THEN p.Cant_realizata ELSE p.Pret_promotional END)>=0.001 
--and (0=0 or p.termen between @dData and @dData)
--and (charindex(','+rtrim(n.grupa)+',','') > 0 or 0 = 0)
--group by p.contract, p.data, p.tert, p.cod

select * from pozaprov pa where pa.tip='BK' and pa.comanda_livrare='12'
	and pa.data_comenzii='2011-12-09'
	 and pa.beneficiar='0212679091913'
	  and pa.cod='0003003' and abs(pa.cant_realizata)<0.001
	  
	  select * from pozaprov where 
	  		Contract='5'            	
		and Data	='2011-12-09 00:00:00.000'
		and Furnizor	='T09076750158D'
