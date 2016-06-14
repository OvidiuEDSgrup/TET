--comenzi clienti
insert into pozaprov
(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
select ':10', ':11', ':8',p.cod, 'BK', 
p.contract, p.data, p.tert, 
sum(p.cant_aprobata)-sum(p.cant_realizata)-isnull((select sum(cant_comandata) from pozaprov pa where pa.tip='BK' and pa.comanda_livrare=p.contract and pa.data_comenzii=p.data and pa.beneficiar=p.tert and pa.cod=p.cod and abs(pa.cant_realizata)<0.001), 0), 
0, 0
from con c inner join pozcon p on c.subunitate=p.subunitate and c.tip=p.tip and c.contract=p.contract and c.data=p.data and c.tert=p.tert
inner join nomencl n on p.cod=n.cod
inner join tempdb..temp_cod_furn:17 pp on pp.cod = n.cod 
where (:25=0 /*and ':13'<>'C'*/ or :25=1)
and c.subunitate=':14' 
and n.tip in ('A', 'M') and p.tip='BK' and (c.stare = ':24' or c.stare='0' and p.UM='1') and (c.tert <> '' or :20 = 1)
and (:4=0 or p.factura=':5') 
and (:6=0 or n.cod like RTrim(':7')) 
and p.cant_aprobata-p.cant_realizata>=0.001 and (:26=0 or p.termen between ':27' and ':28')
and (charindex(','+rtrim(n.grupa)+',',':29') > 0 or :30 = 0)
group by p.contract, p.data, p.tert, p.cod

--comenzi productie
insert into pozaprov
(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
select ':10', ':11', ':8',
l.cod_material, 'C', l.comanda, max(c.data_lansarii), '', 
sum(l.cantitate_necesara)-isnull((select sum(pa.cant_comandata) from pozaprov pa where pa.tip='C' and pa.comanda_livrare=l.comanda and pa.data_comenzii=max(c.data_lansarii) and pa.beneficiar='' and pa.cod=l.cod_material), 0), 
0, 0 
from comenzi c, lansmat l, nomencl n 
where l.cod_material = n.cod and (:25=0 and ':13'='C' or :25=2) and :23=0 and c.subunitate=':14' and c.subunitate=l.subunitate and c.comanda=l.comanda 
and c.tip_comanda in ('P', 'S') and (:26=0 or c.numar_de_inventar between ':27' and ':28' ) 
and (charindex(','+rtrim(n.grupa)+',',':29') > 0 or :30 = 0) and (:6=0 or l.cod_material like RTrim(':7')) and (c.starea_comenzii = ':31' or (:32 = 0 and c.starea_comenzii in ('L','P'))) 
group by l.comanda, l.cod_material

-- necesar de aprovizionare
insert into pozaprov
(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
select ':10', ':11', ':8',
na.cod, 'N', na.numar, na.data, '', 
sum(na.cantitate)-isnull((select sum(pa.cant_comandata) from pozaprov pa where pa.tip='N' and pa.comanda_livrare=na.numar and pa.data_comenzii=na.data and pa.beneficiar='' and pa.cod=na.cod), 0), 
0, 0
from necesaraprov na
inner join nomencl n on na.cod = n.cod
where :23=1 and :25 in (0,2) and na.data between ':1' and ':2' and na.stare='1' and (:4=0 or na.gestiune=':5') 
and (:6=0 or na.cod like RTrim(':7'))  and (charindex(','+rtrim(n.grupa)+',',':29') > 0 or :30 = 0)
group by na.numar, na.data, na.cod

delete from pozaprov where contract=':10' and data=':11' and furnizor=':8' and cant_comandata < 0.001
delete from comaprovtmp where utilizator=':12'

--stoc propriu
insert into comaprovtmp
(Cod, Furnizor, Den_furnizor, Total, Media, Com_clienti, Stoc, Stoc_limita, Comandate, De_aprovizionat, Pret, Termen, Utilizator, Com_interne)
select n.cod, pp.furnizor, 
isnull((select max(b.denumire) from terti b where b.tert=pp.furnizor),'<err.>') as den_furn,
--total vanzari/consumuri
(case when :25<>0 then 0 else isnull((select sum(c.cantitate) from pozdoc c 
	left outer join gestiuni g on g.cod_gestiune = c.gestiune_primitoare
	where ((':13'='V' and (c.tip in ('AP','AC') or (c.tip = 'TE' and g.tip_gestiune = 'V'))) or (':13'='C' and c.tip = 'CM')) and c.data between ':1' and ':2' and c.cod=n.cod and (:4=0 or c.gestiune=':5')),0) end) as total,
--media vanzari/consumuri
(case when :25<>0 then 0 when ':13' = 'S' then isnull((select max(stoc_max) from stoclim where ((:4=0 and stoclim.cod_gestiune = '') or (:4=1 and stoclim.cod_gestiune = ':5')) and stoclim.cod = n.cod and stoclim.data<='01/01/2999'),0)
	else isnull((select sum(c.cantitate) from pozdoc c 
	left outer join gestiuni g on g.cod_gestiune = c.gestiune_primitoare
	where ((':13'='V' and (c.tip in ('AP','AC') or (c.tip = 'TE' and g.tip_gestiune = 'V'))) or (':13'='C' and c.tip = 'CM')) and c.data between ':1' and ':2' and c.cod=n.cod and (:4=0 or c.gestiune=':5')),0) / (1 + datediff(day,':1',':2'))*(:3)  end )as media,
--comenzi de livrare
0 as com_clienti,
--stoc scriptic actual
isnull((select sum(e.stoc) from stocuri e where e.cod=n.cod and (:4=0 or e.cod_gestiune=':5')),0) as stoc, 
--stoc limita
(case when :25<>0 then 0 else sum(isnull(sl.stoc_min, 0)) end) as stoc_limita, 
--comenzi anterioare pt. stoc propriu
(case when :25 not in (0, 1) then 0 else isnull((select sum(pa.cant_comandata-pa.cant_receptionata) from pozaprov pa inner join pozcon g 
			on pa.contract=g.contract and pa.data=g.data and pa.furnizor=g.tert and pa.cod=g.cod 
			where g.tip='FC' and (:4=0 OR 0=0 or g.factura=':5') and g.cod=n.cod and pa.furnizor=':8' and 
			(pa.contract<>':10' or pa.data<>':11') and pa.tip='' and pa.comanda_livrare='' and pa.cant_comandata-pa.cant_receptionata>=0.001),0) end) as comandate,
0 as de_aprovizionat, 
(case when :9=1 then isnull((select top 1 pret_vanzare from preturi p where p.cod_produs=n.cod and p.tip_pret='1' and p.um='1' order by data_inferioara desc), max(n.pret_vanzare)) else max(n.pret_stoc) end) as pret,
(case when :15 = 0 then ':16' when :15 = 1 then
isnull((select dateadd(day,:18*(-1),min(termen)) from pozcon pc where pc.cod = n.cod and pc.tip = 'BK' 
and pc.cant_aprobata-pc.cant_realizata>=0.001 and pc.contract in (select comanda_livrare from pozaprov where tip='BK' and contract = ':10')),':16')
else ':11' end), ':12', 
--comenzi de productie 
0 as Com_interne
from nomencl n
inner join tempdb..temp_cod_furn:17 pp on pp.cod = n.cod
left outer join stoclim sl on n.cod=sl.cod and ((:4=1 and sl.cod_gestiune=':5') or (:4=0 and sl.cod_gestiune='')) and sl.data<='01/01/2999'
where n.tip in ('A', 'M') and (:6=0 or n.cod like RTrim(':7')) and (charindex(','+rtrim(n.grupa)+',',':29') > 0 or :30 = 0)
group by n.cod, pp.furnizor

if :15 = 2 update comaprovtmp set termen = dateadd(day,(select isnull(max(p.nr_zile_livrare),0) from ppreturi p where comaprovtmp.cod = p.cod_resursa and comaprovtmp.furnizor = p.tert),termen)

update comaprovtmp
set com_clienti = isnull((select sum(cant_comandata) from pozaprov p where p.contract=':10' and p.data=':11' and p.furnizor=':8' and p.cod=comaprovtmp.cod and p.tip='BK' and p.comanda_livrare<>'' group by p.cod), 0),
com_interne = isnull((select sum(cant_comandata) from pozaprov p where p.contract=':10' and p.data=':11' and p.furnizor=':8' and p.cod=comaprovtmp.cod and p.tip in ('C', 'N') and p.comanda_livrare<>'' group by p.cod), 0)
where utilizator=':12'

delete from comaprovtmp where :9=1 and total=0 and com_clienti=0 and com_interne=0 and stoc_limita=0 and utilizator=':12'
delete from pozaprov where contract=':10' and data=':11' and furnizor=':8' and cod not in (select distinct cod from comaprovtmp where utilizator=':12')

if :21=0 
begin
	update comaprovtmp set de_aprovizionat=(case when ':13'='S' then (media-stoc_limita) else media end)+stoc_limita-stoc-comandate where utilizator=':12'
	if :22=0 update comaprovtmp set de_aprovizionat=0 where de_aprovizionat<0.001 and utilizator=':12'
end

if :21=1 
	update comaprovtmp 
	set de_aprovizionat = media * (select  isnull(max(p.nr_zile_livrare),0) from ppreturi p where comaprovtmp.cod = p.cod_resursa and comaprovtmp.furnizor = p.tert) 
	+ :3 * (select  isnull(max(p.nr_zile_livrare),0) from ppreturi p where comaprovtmp.cod = p.cod_resursa and comaprovtmp.furnizor = p.tert) 
	where utilizator = ':12'

insert into pozaprov
(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
select ':10', ':11', ':8', cod, '', '', ':11', '', 
sum(de_aprovizionat), 0, 0
from comaprovtmp
where utilizator=':12'
group by cod having sum(de_aprovizionat)>0

update comaprovtmp set de_aprovizionat=de_aprovizionat+com_clienti+com_interne where utilizator=':12'
if :19=1 update comaprovtmp set de_aprovizionat= 0  where utilizator=':12' and stoc>=stoc_limita

if :22=1 
	update comaprovtmp set de_aprovizionat = (floor(de_aprovizionat/p.cant_minima)+1) * p.cant_minima
	from ppreturi p where p.cod_resursa = comaprovtmp.cod and p.tert = comaprovtmp.furnizor  and de_aprovizionat > 0--and p.cant_minima > comaprovtmp.de_aprovizionat 

update comaprovtmp set de_aprovizionat=0 where de_aprovizionat<0.001 and utilizator=':12'

delete from pozaprov where contract=':10' and data=':11' and furnizor=':8' and cod in (select cod from comaprovtmp where utilizator=':12' group by cod having sum(de_aprovizionat)<0.001) and comanda_livrare <> ''
delete from pozaprov where contract=':10' and data=':11' and furnizor=':8' and tip='' and comanda_livrare='' and abs(cant_comandata)<0.001 
	and exists (select 1 from pozaprov p1 where p1.contract=':10' and p1.data=':11' and p1.furnizor=':8' and p1.cod=pozaprov.cod and p1.cant_comandata>=0.001)

delete from comaprovtmp where :25 in (1,2) and total=0 and com_clienti=0 and com_interne=0 and stoc_limita=0 and utilizator=':12'
