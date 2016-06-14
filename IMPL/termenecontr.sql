select * from pozcon where tert='0212679091913' and tip='bf'
select * from termene
select distinct tip from pozcon


--INSERT termene
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

--UPDATE par
SET Val_logica=1
WHERE Tip_parametru='GE' AND Parametru='GNC'

select * 
into termene_coduri_mari
from Termene t
where len(t.Cod)>20

--DELETE termene
from Termene t
where len(t.Cod)>20


--TRUNCATE TABLE termene
--INSERT termene
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

select * from pozcon 
where Subunitate='EXPAND' and cod='1800033017211'

--DELETE termene
where tip in ('BF','FA')

DROP TABLE ATPURI_POZCON
SELECT TOP 0 * 
INTO ATPURI_POZCON
FROM pozcon

--TRUNCATE TABLE ATPURI_POZCON
--INSERT ATPURI_POZCON
SELECT 
'EXPAND'
, p.Tip
, p.Contract
, p.Tert
, ''
, p.Data
, p.Cod
, 0
, 0
, 0
, 0
, ''
, ''
,0
, 0
, 0
, ''
, 0
, 0
, ''
, ''
,''
, LEFT(pr.Valoare,200)
, p.Numar_pozitie
, p.Utilizator
, p.Data_operarii
, p.Ora_operarii
FROM pozcon p JOIN proprietati pr ON pr.Tip='NOMENCL' AND pr.Cod=p.Cod AND pr.Cod_proprietate='ATP'
where p.Tip='FA'

--INSERT pozcon
select * from ATPURI_POZCON a where not exists 
(select 1 from pozcon p where p.Subunitate=a.Subunitate and p.Tip=a.Tip and p.Data=a.Data and p.Contract=a.Contract and p.Tert=a.Tert 
and p.Cod=a.Cod and p.Numar_pozitie=a.Numar_pozitie)

select cod from proprietati pr
where pr.Tip='NOMENCL' AND PR.Cod_proprietate='ATP' 
GROUP BY pr.Cod
having COUNT(*)>1

--UPDATE pozcon
SET explicatii=a.explicatii
from pozcon p join ATPURI_POZCON a ON p.Subunitate=a.Subunitate and p.Tip=a.Tip and p.Data=a.Data and p.Contract=a.Contract and p.Tert=a.Tert 
and p.Cod=a.Cod and p.Numar_pozitie=a.Numar_pozitie