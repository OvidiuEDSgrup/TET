with g as (
select c.Tip,c.Contract,dataj=MIN(data),datas=MAX(data)--,MIN(stare),MAX(stare)
--,ROW_NUMBER() over(order by MIN(data))
from con c
group by c.Tip,c.Contract
having COUNT(1)>1
), c as (
select nrcrt=ROW_NUMBER() over ( partition by c.tip, c.contract order by c.data desc, c.stare desc, c.tert desc)-1
,c.*
from con c join g on g.Tip=c.Tip and g.Contract=c.Contract
), a as (select id=1,cod=46 union all select id=2,cod=44 union all select id=3,cod=45 union all select id=4,cod=47)
select char(a.cod),n.*
--update n set contract=RTRIM(n.Contract)+isnull(char(a.cod),'')
from con n join c on c.Subunitate=n.Subunitate and c.Tip=n.Tip and c.Data=n.Data and c.Contract=n.Contract and c.Tert=n.Tert
left join a on a.id=c.nrcrt
--select ASCII('.'),CHAR(44),CHAR(45),CHAR(46),CHAR(47)
--order by c.tip, c.contract ,c.data desc, c.stare desc, c.tert desc

select c.Tip,max(c.numar),dataj=MIN(data),datas=MAX(data)--,MIN(stare),MAX(stare)
,COUNT(1)
--,ROW_NUMBER() over(order by MIN(data))
from Contracte c
group by c.Tip--,c.numar
--having COUNT(1)>1
--select 
--delete Contracte
--where tip<>'RN'

--select *
----delete p
--from pozcontracte p join contracte c on c.idContract=p.idContract
--where c.tip<>'RN'

--select *
----delete p
--from JurnalContracte p join contracte c on c.idContract=p.idContract
--where c.tip<>'RN'

;with g as (
select c.Tip,c.Contract,dataj=MIN(data),datas=MAX(data)--,MIN(stare),MAX(stare)
--,ROW_NUMBER() over(order by MIN(data))
from pozcon c
group by c.Tip,c.Contract
having COUNT(distinct tert+RTRIM(data))>1
), c as (
select nrcrt=dense_rank() over ( partition by c.tip, c.contract order by c.data desc
	--, sum(c.cant_realizata) over(partition by c.tip, c.contract ) desc
	 , z.cant_realizata desc
	, c.tert desc)-1
,z_cant_realizata=z.cant_realizata,c.*
from pozcon c join g on g.Tip=c.Tip and g.Contract=c.Contract
	cross apply (select cant_realizata=SUM(z.cant_realizata) from pozcon z where z.Subunitate=c.subunitate and z.Tip=c.tip and z.Contract=c.contract and z.Data=c.data and z.Tert=c.tert) z
), a as (select id=1,cod=46 union all select id=2,cod=44 union all select id=3,cod=45 union all select id=4,cod=47)
--select a.id,char(a.cod),n.*
update n set contract=RTRIM(n.Contract)+isnull(char(a.cod),'')
from pozcon n join c on n.idPozCon=c.idPozCon--c.Subunitate=n.Subunitate and c.Tip=n.Tip and c.Data=n.Data and c.Contract=n.Contract and c.Tert=n.Tert
left join a on a.id=c.nrcrt
--order by c.tip, c.contract, c.data desc, z_cant_realizata desc, c.tert desc