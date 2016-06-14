if 0=1
 update con
 set stare='2'
 from terti
 where con.subunitate='1        ' and con.tip='BK' and con.stare='0' 
 and terti.subunitate=con.subunitate and terti.tert=con.tert
 and terti.sold_maxim_ca_beneficiar>=0.01
 and (isnull((select sum(facturi.sold) from facturi where facturi.subunitate=terti.subunitate and facturi.tip=0x46 and facturi.tert=terti.tert), 0)
  +isnull((select sum(sold) from efecte where efecte.subunitate=terti.subunitate and efecte.tip='I' and efecte.tert=terti.tert), 0))
  -terti.sold_maxim_ca_beneficiar>=0.01

insert into pozcomlivrtmp
(utilizator, cod, comanda, tert, cant_comandata, cant_aprobata, termen, numar_document, data_document, stare, selectat, observatii)
select 'OVIDIU', p.cod, p.contract, p.tert, sum(p.cantitate), 
sum(case when p.cant_aprobata>(case when p.punct_livrare='' then p.cant_realizata else p.pret_promotional end) 
then p.cant_aprobata-(case when p.punct_livrare='' then p.cant_realizata else p.pret_promotional end) else 0 end),
min(p.termen), '', '01/01/1901', '', 0, ''
from pozcon p 
inner join con c on p.subunitate = c.subunitate and p.tip = c.tip and p.contract = c.contract and p.data = c.data and p.tert = c.tert 
inner join nomencl n on p.cod = n.cod
left outer join terti t on t.subunitate=p.subunitate and t.tert=p.tert
where p.subunitate = '1        ' and p.tip = 'BK' and c.stare = '0' and p.cantitate>0 and n.tip not in ('R', 'S')
and (0  = 0 or p.factura = '101      ')
and (0  = 0 or charindex(';' + rtrim(p.punct_livrare) + ';', ';;') > 0) 
and (0  = 0 or charindex(';' + rtrim(n.grupa) + ';', ';;') > 0) 
and (0  = 0 or charindex(';' + rtrim(p.contract) + ';', ';;') > 0) 
and ((0 = 0 or charindex(';' + rtrim(c.loc_de_munca) + ';', '') > 0) 
or (0 = 0 or rtrim(c.loc_de_munca)  like '%'))
and (0 = 0 or p.data between '02/01/2012' and '02/29/2012')
and (0 = 0 or p.termen between '02/01/2012' and '02/29/2012')
and (0 = 0 or n.grupa like RTrim('             ')+'%')
and (0 = 0 or charindex(';' + rtrim(isnull(t.grupa,'')) + ';', ';;') > 0) 
and (0 = 0 or charindex(';' + rtrim(p.tert) + ';', ';;') > 0) 
and (0 = 0 or charindex(';' + rtrim(c.punct_livrare) + ';', ';;') > 0)
and (0=0 or c.mod_penalizare like rtrim('                                                                                                    ')+'%')
group by p.cod, p.contract, p.tert

insert into comlivrtmp
(utilizator, cod, cant_comandata, stoc, cant_aprobata, aprobat_alte, stare)
select 'OVIDIU', cod, sum(cant_comandata), 0, sum(cant_aprobata), 0, ''
from pozcomlivrtmp
where utilizator='OVIDIU'
group by cod

update comlivrtmp
set stoc = isnull((select sum(stoc) from stocuri s 
 where s.subunitate='1        ' and (0=0 or s.cod_gestiune='101      ') and s.cod=comlivrtmp.cod), 0)
where utilizator='OVIDIU'

update comlivrtmp
set aprobat_alte = isnull((select sum(case when p.cant_aprobata>(case when p.punct_livrare='' then p.cant_realizata else p.pret_promotional end) 
	then p.cant_aprobata-(case when p.punct_livrare='' then p.cant_realizata else p.pret_promotional end) else 0 end) 
 from pozcon p where p.subunitate='1        ' and p.tip='BK'  
and (select max(stare) from con where subunitate = p.subunitate and tip = p.tip and contract = p.contract and data = p.data and tert = p.tert)<='1' 
and p.cod=comlivrtmp.cod and (0=0 or p.factura='101      ')), 0)
where utilizator='OVIDIU'

update comlivrtmp
set aprobat_alte = aprobat_alte - cant_aprobata
where utilizator='OVIDIU'

select * from comlivrtmp
select * from pozcomlivrtmp
SELECT * FROM POZCON WHERE TIP='BK' AND Cod='00601101'