--comenzi clienti
insert into pozaprov
(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
select '103', '02/02/2012', 'IT09076750158',p.cod, 'BK', 
p.contract, p.data, p.tert, 
sum(p.cant_aprobata)-sum(p.cant_realizata)-isnull((select sum(cant_comandata) from pozaprov pa where pa.tip='BK' and pa.comanda_livrare=p.contract and pa.data_comenzii=p.data and pa.beneficiar=p.tert and pa.cod=p.cod and abs(pa.cant_realizata)<0.001), 0), 
0, 0
from con c inner join pozcon p on c.subunitate=p.subunitate and c.tip=p.tip and c.contract=p.contract and c.data=p.data and c.tert=p.tert
inner join nomencl n on p.cod=n.cod
inner join tempdb..temp_cod_furn7964 pp on pp.cod = n.cod 
where (1 =0 /*and 'V'<>'C'*/ or 1 =1)
and c.subunitate='1' 
and n.tip in ('A', 'M') and p.tip='BK' and (c.stare = '5' or c.stare='0' and p.UM='1') and (c.tert <> '' or 0 = 1)
and (1=0 or p.factura='101') 
and (0=0 or n.cod like RTrim('')) 
and p.cant_aprobata-p.cant_realizata>=0.001 and (0=0 or p.termen between '2012/02/02' and '2012/02/02')
and (charindex(','+rtrim(n.grupa)+',','') > 0 or 0 = 0)
group by p.contract, p.data, p.tert, p.cod

--comenzi productie
insert into pozaprov
(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
select '103', '02/02/2012', 'IT09076750158',
l.cod_material, 'C', l.comanda, max(c.data_lansarii), '', 
sum(l.cantitate_necesara)-isnull((select sum(pa.cant_comandata) from pozaprov pa where pa.tip='C' and pa.comanda_livrare=l.comanda and pa.data_comenzii=max(c.data_lansarii) and pa.beneficiar='' and pa.cod=l.cod_material), 0), 
0, 0 
from comenzi c, lansmat l, nomencl n 
where l.cod_material = n.cod and (1 =0 and 'V'='C' or 1 =2) and 1=0 and c.subunitate='1' and c.subunitate=l.subunitate and c.comanda=l.comanda 
and c.tip_comanda in ('P', 'S') and (0=0 or c.numar_de_inventar between '2012/02/02' and '2012/02/02' ) 
and (charindex(','+rtrim(n.grupa)+',','') > 0 or 0 = 0) and (0=0 or l.cod_material like RTrim('')) and (c.starea_comenzii = 'P' or (0 = 0 and c.starea_comenzii in ('L','P'))) 
group by l.comanda, l.cod_material

-- necesar de aprovizionare
insert into pozaprov
(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
select '103', '02/02/2012', 'IT09076750158',
na.cod, 'N', na.numar, na.data, '', 
sum(na.cantitate)-isnull((select sum(pa.cant_comandata) from pozaprov pa where pa.tip='N' and pa.comanda_livrare=na.numar and pa.data_comenzii=na.data and pa.beneficiar='' and pa.cod=na.cod), 0), 
0, 0
from necesaraprov na
inner join nomencl n on na.cod = n.cod
where 1=1 and 1  in (0,2) and na.data between '01/01/2012' and '01/31/2012' and na.stare='1' and (1=0 or na.gestiune='101') 
and (0=0 or na.cod like RTrim(''))  and (charindex(','+rtrim(n.grupa)+',','') > 0 or 0 = 0)
group by na.numar, na.data, na.cod

delete from pozaprov where contract='103' and data='02/02/2012' and furnizor='IT09076750158' and cant_comandata < 0.001
delete from comaprovtmp where utilizator='OVIDIU'

--stoc propriu
insert into comaprovtmp
(Cod, Furnizor, Den_furnizor, Total, Media, Com_clienti, Stoc, Stoc_limita, Comandate, De_aprovizionat, Pret, Termen, Utilizator, Com_interne)
select n.cod, pp.furnizor, 
isnull((select max(b.denumire) from terti b where b.tert=pp.furnizor),'<err.>') as den_furn,
--total vanzari/consumuri
(case when 1 <>0 then 0 else isnull((select sum(c.cantitate) from pozdoc c 
 left outer join gestiuni g on g.cod_gestiune = c.gestiune_primitoare
 where (('V'='V' and (c.tip in ('AP','AC') or (c.tip = 'TE' and g.tip_gestiune = 'V'))) or ('V'='C' and c.tip = 'CM')) and c.data between '01/01/2012' and '01/31/2012' and c.cod=n.cod and (1=0 or c.gestiune='101')),0) end) as total,
--media vanzari/consumuri
(case when 1 <>0 then 0 when 'V' = 'S' then isnull((select max(stoc_max) from stoclim where ((1=0 and stoclim.cod_gestiune = '') or (1=1 and stoclim.cod_gestiune = '101')) and stoclim.cod = n.cod and stoclim.data<='01/01/2999'),0)
 else isnull((select sum(c.cantitate) from pozdoc c 
 left outer join gestiuni g on g.cod_gestiune = c.gestiune_primitoare
 where (('V'='V' and (c.tip in ('AP','AC') or (c.tip = 'TE' and g.tip_gestiune = 'V'))) or ('V'='C' and c.tip = 'CM')) and c.data between '01/01/2012' and '01/31/2012' and c.cod=n.cod and (1=0 or c.gestiune='101')),0) / (1 + datediff(day,'01/01/2012','01/31/2012'))*( 31 )  end )as media,
--comenzi de livrare
0 as com_clienti,
--stoc scriptic actual
isnull((select sum(e.stoc) from stocuri e where e.cod=n.cod and (1=0 or e.cod_gestiune='101')),0) as stoc, 
--stoc limita
(case when 1 <>0 then 0 else sum(isnull(sl.stoc_min, 0)) end) as stoc_limita, 
--comenzi anterioare pt. stoc propriu
(case when 1  not in (0, 1) then 0 else isnull((select sum(pa.cant_comandata-pa.cant_receptionata) from pozaprov pa inner join pozcon g 
   on pa.contract=g.contract and pa.data=g.data and pa.furnizor=g.tert and pa.cod=g.cod 
   where g.tip='FC' and (1=0 OR 0=0 or g.factura='101') and g.cod=n.cod and pa.furnizor='IT09076750158' and 
   (pa.contract<>'103' or pa.data<>'02/02/2012') and pa.tip='' and pa.comanda_livrare='' and pa.cant_comandata-pa.cant_receptionata>=0.001),0) end) as comandate,
0 as de_aprovizionat, 
(case when 0=1 then isnull((select top 1 pret_vanzare from preturi p where p.cod_produs=n.cod and p.tip_pret='1' and p.um='1' order by data_inferioara desc), max(n.pret_vanzare)) else max(n.pret_stoc) end) as pret,
(case when 