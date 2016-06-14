select * from pozcon where tert='0212679091913' and tip='bf'
select * from termene
select distinct tip from pozcon

TRUNCATE TABLE termene
insert termene
SELECT --*,
p.subunitate --Subunitate	char	no	9
,p.tip --Tip	char	no	2
,p.Contract --Contract	char	no	20
,p.Tert --Tert	char	no	13
,p.Cod --Cod	char	no	20
,p.Data --Data	datetime	no	8
,DATEADD(DAY,max(c.scadenta),p.Data) --Termen	datetime	no	8
,max(p.Cantitate )--Cantitate	float	no	8
,0 --Cant_realizata	float	no	8
,MAX(p.Pret) --Pret	float	no	8
,'' --Explicatii	char	no	200
,0 --Val1	float	no	8
,0 --Val2	float	no	8
,'' --Data1	datetime	no	8
,'' --Data2	datetime	no	8
FROM pozcon p JOIN con c ON p.Subunitate=c.Subunitate and p.Tip=c.Tip and p.Data=c.Data and p.Tert=c.Tert
	and p.Contract=c.Contract
WHERE p.Tip in ('BF','FA')
group by p.Subunitate, p.Tip, p.Contract, p.Tert, p.Cod, p.Data

select Subunitate, Tip, Contract, Tert, Cod, Data, MAX(pret),MIN(pret)
from pozcon where tip in ('bf','fa')
group by Subunitate, Tip, Contract, Tert, Cod, Data
having COUNT(*)>1

select * from pozcon where Contract='5'

select * from par
where Denumire_parametru like '%gara%'

UPDATE par
SET Val_logica=1
WHERE Tip_parametru='GE' AND Parametru='GNC'