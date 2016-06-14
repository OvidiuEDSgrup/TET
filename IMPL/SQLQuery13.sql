exec sys.sp_executesql N'SELECT A.Utilizator,A.Cod,A.Cant_comandata,A.Stoc,A.Cant_aprobata,A.Aprobat_alte,A.Stare,B.Cod,B.Denumire FROM TET..comlivrtmp A, TET..nomencl B WHERE A.Utilizator = @P1  AND B.Cod = A.Cod AND ((0x00=0 or convert(decimal(12,3), A.Cant_comandata-A.Cant_aprobata)>=0.001)) ORDER BY A.Utilizator ASC ,A.Cod ASC ',N'@P1 char(10)','OVIDIU    '
select * from comlivrtmp

select Contract,cod, COUNT(distinct tert), MAX(tert), MAX(data) 
from pozcon
where tip='bk'  and Subunitate='1'
group by Contract,cod
having COUNT(tert)>1

select nr,* from pozcon p join
(select Contract,cod,tert,ROW_NUMBER() OVER(PARTITION BY contract,cod ORDER BY tert) nr
from pozcon p
where p.Tip='bk' ) drv on drv.Contract=p.contract and drv.Cod=p.Cod and drv.Tert=p.Tert
where drv.nr>1 and Subunitate='1'

delete pozcon
 from pozcon p join
(select Contract,cod,tert,ROW_NUMBER() OVER(PARTITION BY contract,cod ORDER BY tert) nr
from pozcon p
where p.Tip='bk' ) drv on drv.Contract=p.contract and drv.Cod=p.Cod and drv.Tert=p.Tert
where drv.nr>1 and Subunitate='1'