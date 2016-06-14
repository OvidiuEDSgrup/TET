select * 
--INTO PRETURIDX
from PRETURI

----TRUNCATE TABLE PRETURIDX
----INSERT PRETURIDX
SELECT --*, 
LEFT(COD,30) --Cod_produs	char	no	30	     
,1 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,GETDATE() --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,PRET --Pret_vanzare	float	no	8	53   
,PRET*1.24 --Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT MAX(LEN(COD))
FROM PRETCATEUR

select * from PRETCATEUR where cod like '%016-200%'



SELECT Cod_produs, UM, Tip_pret, Data_inferioara, Ora_inferioara, Ora_superioara, Ora_operarii
FROM preturiDX
GROUP BY Cod_produs, UM, Tip_pret, Data_inferioara, Ora_inferioara, Ora_superioara, Ora_operarii
HAVING COUNT(*)>1

select * from preturi where Cod_produs='0003000'

----TRUNCATE TABLE PRETURIDX
----INSERT PRETURIDX
SELECT --*, 
LEFT(COD,30) --Cod_produs	char	no	30	     
,2 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,GETDATE() --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,PRET --Pret_vanzare	float	no	8	53   
,PRET*1.24 --Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT *
FROM PRETCATUSD


------TRUNCATE TABLE PRETURIDX
----INSERT PRETURIDX
SELECT --*, 
LEFT(COD,30) --Cod_produs	char	no	30	     
,1 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,GETDATE() --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,CONVERT(FLOAT,PRET )--Pret_vanzare	float	no	8	53   
,CONVERT(FLOAT,PRET)*1.24 --Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT MAX(LEN(COD))
FROM PRETCATEURTOT

----TRUNCATE TABLE PRETURI
----INSERT PRETURI
SELECT * FROM PRETURIDX

SELECT * FROM PRETURI P WHERE P.Cod_produs NOT IN
(SELECT COD FROM NOMENCL)

SELECT TOP 0 *
INTO NOMENCLPRETIDX
FROM NOMENCL

----INSERT NOMENCLPRETIDX
SELECT --*
LEFT(COD,30)	--Cod	char	no	30
,'M'	--Tip	char	no	1
,LEFT(P.DENUMIRE,150)	--Denumire	char	no	150
,''	--UM	char	no	3
,''	--UM_1	char	no	3
,0	--Coeficient_conversie_1	float	no	8
,''	--UM_2	char	no	20
,0	--Coeficient_conversie_2	float	no	8
,''	--Cont	char	no	13
,''	--Grupa	char	no	13
,LEFT(P.MONEDA,3)	--Valuta	char	no	3
,CONVERT(FLOAT, P.PRET) --Pret_in_valuta	float	no	8
,CONVERT(FLOAT, P.PRET)	--Pret_stoc	float	no	8
,CONVERT(FLOAT, P.PRET)	--Pret_vanzare	float	no	8
,0	--Pret_cu_amanuntul	float	no	8
,24	--Cota_TVA	real	no	4
,0	--Stoc_limita	float	no	8
,0	--Stoc	float	no	8
,0	--Greutate_specifica	float	no	8
,''	--Furnizor	char	no	13
,''	--Loc_de_munca	char	no	150
,'101'	--Gestiune	char	no	13
,1	--Categorie	smallint	no	2
,''	--Tip_echipament	char	no	21
-- SELECT * 
FROM PRETCATEURTOT P

----INSERT NOMENCLPRETIDX
SELECT --*
LEFT(COD,30)	--Cod	char	no	30
,'M'	--Tip	char	no	1
,LEFT(P.DENUMIRE,150)	--Denumire	char	no	150
,''	--UM	char	no	3
,''	--UM_1	char	no	3
,0	--Coeficient_conversie_1	float	no	8
,''	--UM_2	char	no	20
,0	--Coeficient_conversie_2	float	no	8
,''	--Cont	char	no	13
,''	--Grupa	char	no	13
,LEFT(P.MONEDA,3)	--Valuta	char	no	3
,CONVERT(FLOAT, P.PRET) --Pret_in_valuta	float	no	8
,CONVERT(FLOAT, P.PRET)	--Pret_stoc	float	no	8
,CONVERT(FLOAT, P.PRET)	--Pret_vanzare	float	no	8
,0	--Pret_cu_amanuntul	float	no	8
,24	--Cota_TVA	real	no	4
,0	--Stoc_limita	float	no	8
,0	--Stoc	float	no	8
,0	--Greutate_specifica	float	no	8
,''	--Furnizor	char	no	13
,''	--Loc_de_munca	char	no	150
,'101'	--Gestiune	char	no	13
,2	--Categorie	smallint	no	2
,''	--Tip_echipament	char	no	21
-- SELECT * 
FROM PRETCATUSD P
WHERE LEFT(COD,30) NOT IN (SELECT COD FROM NOMENCLPRETIDX)

----INSERT NOMENCL
SELECT * 
FROM NOMENCLPRETIDX
WHERE COD NOT IN 
(SELECT COD FROM NOMENCL)

--UPDATE NOMENCL
SET Valuta=n.valuta,
Pret_in_valuta=n.Pret_in_valuta,
Pret_stoc=n.Pret_stoc,
Pret_vanzare=n.Pret_vanzare,
Categorie=n.Categorie
from nomencl join NOMENCLPRETIDX n on nomencl.Cod=N.cod

select * 
into preturi_coduri_mari
from preturi p 
where len(p.Cod_produs)>20

--DELETE preturi
from preturi p 
where len(p.Cod_produs)>20

select * from preturi p
where p.Cod_produs not in (select cod from nomencl)

----INSERT preturi
select 
n.codnou
,p.UM
,p.Tip_pret
,p.Data_inferioara
,p.Ora_inferioara
,p.Data_superioara
,p.Ora_superioara
,p.Pret_vanzare
,p.Pret_cu_amanuntul
,p.Utilizator
,p.Data_operarii
,p.Ora_operarii 
from preturi_coduri_mari p join nomencl_coduri_mari n on p.Cod_produs=n.cod

select * 
INTO PRETURI_STOC_MAG_NT
from PRETURI

----TRUNCATE TABLE PRETURI_STOC_MAG_NT
----INSERT PRETURI_STOC_MAG_NT
SELECT --*, 
LEFT(s.cod ,30) --Cod_produs	char	no	30	     
,4 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,'2012-01-01' --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,s.Pret_vanzare --Pret_vanzare	float	no	8	53   
,s.Pret_cu_amanuntul --Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT MAX(LEN(COD))
FROM STOC_MAG_NT_CODURI_LIPSA s

----INSERT preturi
select * from PRETURI_STOC_MAG_NT


select * 
INTO PRETURI_PROD_MAG
from PRETURI

---- TRUNCATE TABLE PRETURI_PROD_MAG
---- INSERT PRETURI_PROD_MAG
SELECT --*, 
max(LEFT(p.cod ,20)) --Cod_produs	char	no	30	     
,4 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,'2012-01-01' --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,MAX(CONVERT(FLOAT,P.[Pret_cu_TVA ])*(1.24))--Pret_vanzare	float	no	8	53   
,MAX(CONVERT(FLOAT,P.[Pret_cu_TVA ]))--Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT MAX(LEN(COD))
FROM PROD_MAG_Erata_si_Ever_Pro p
group by P.COD

UPDATE preturi
set Pret_vanzare=pt.Pret_vanzare
,Pret_cu_amanuntul=pt.Pret_cu_amanuntul
from preturi p join PRETURI_PROD_MAG pt on pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret

---- INSERT preturi
select * from PRETURI_PROD_MAG P
WHERE NOT EXISTS (select 1 from preturi pt where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret)

select (p.Pret_cu_amanuntul*(1+24/100)) ,* from preturi p where um=4


select * 
INTO PRETURI_PROD_MAG_DJ
from PRETURI

---- TRUNCATE TABLE PRETURI_PROD_MAG_DJ INSERT PRETURI_PROD_MAG_DJ
SELECT --*, 
max(LEFT(p.cod ,20)) --Cod_produs	char	no	30	     
,4 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,'2012-01-01' --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,MAX(CONVERT(FLOAT,P.pret_vanz_cu_TVA)/(1.24))--Pret_vanzare	float	no	8	53   
,MAX(CONVERT(FLOAT,P.pret_vanz_cu_TVA))--Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT *
FROM PRETURI_VANZARE_MAG_DJ p
group by P.COD

UPDATE preturi
set Pret_vanzare=pt.Pret_vanzare
,Pret_cu_amanuntul=pt.Pret_cu_amanuntul
from preturi p join PRETURI_PROD_MAG_DJ pt on pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret

INSERT preturi
select * from PRETURI_PROD_MAG_DJ P
WHERE NOT EXISTS (select 1 from preturi pt where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret)

select * 
INTO PRETURI_MAGAZIN_ULTIM
from PRETURI

alter table PRETURI_MAGAZIN_ULTIM alter column cod_produs char(25) not null

---- TRUNCATE TABLE PRETURI_MAGAZIN_ULTIM INSERT PRETURI_MAGAZIN_ULTIM
SELECT --*, 
max(LEFT(p.cod ,25)) --Cod_produs	char	no	30	     
,4 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,'2012-01-01' --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,MAX(CONVERT(FLOAT,REPLACE(P.[pret aman RON cu TVA],',','')))/(1.24)--Pret_vanzare	float	no	8	53   
,MAX(CONVERT(FLOAT,REPLACE(P.[pret aman RON cu TVA],',','')))--Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT *
--TOP 300 cod, max(P.[pret aman RON cu TVA]) 
FROM PRETURI_MAGAZIN1 p
--where len(cod)<=20 --and cod='00630101'
group by P.COD

--INSERT preturi
select * from PRETURI_MAGAZIN_ULTIM P
WHERE NOT EXISTS (select 1 from preturi pt where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret)

SELECT Cod_produs, UM, Tip_pret, Data_inferioara, Ora_inferioara, Ora_superioara, Ora_operarii
FROM PRETURI_MAGAZIN_ULTIM
GROUP BY Cod_produs, UM, Tip_pret, Data_inferioara, Ora_inferioara, Ora_superioara, Ora_operarii
HAVING COUNT(*)>1

--update PRETURI_MAGAZIN_ULTIM
set Cod_produs=codnou
from PRETURI_MAGAZIN_ULTIM p join nomencl_coduri_mari n on n.Cod=p.Cod_produs

SELECT *
--TOP 300 cod, max(P.[pret aman RON cu TVA]) 
FROM PRETURI_MAGAZIN_ULTIM p
where cod_produs='00630101'
where len(cod_produs)>20

select n.Denumire, p.* from preturi P join nomencl n on p.Cod_produs=n.Cod
WHERE EXISTS (select 1 from PRETURI_MAGAZIN_ULTIM pt 
where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret) 
and exists (select 1 from PRETURI_MAGAZIN_ULTIM pt 
where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret 
and pt.Pret_vanzare<>p.Pret_vanzare and pt.Pret_cu_amanuntul<>p.Pret_cu_amanuntul)

--UPDATE preturi
set Pret_vanzare=pt.Pret_vanzare
,Pret_cu_amanuntul=pt.Pret_cu_amanuntul
from preturi p join PRETURI_MAGAZIN_ULTIM pt on pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret

select TOP 0 *
into STOC_MAGAZIN_CODURI_LIPSA
FROM NOMENCL
ALTER TABLE STOC_MAGAZIN_CODURI_LIPSA 
ALTER COLUMN COD CHAR(25) NOT NULL

-- TRUNCATE TABLE STOC_MAGAZIN_CODURI_LIPSA INSERT STOC_MAGAZIN_CODURI_LIPSA
SELECT --*,
LEFT(Cod,30)	--Cod	char	30
,'M'	--Tip	char	1
,LEFT(MAX(S.[Denumirea produsului]),150)	--Denumire	char	150
,LEFT(MAX(S.UM),3)	--UM	char	3
,''	--UM_1	char	3
,0	--Coeficient_conversie_1	float	8
,''	--UM_2	char	20
,0	--Coeficient_conversie_2	float	8
,LEFT('371.1',13)	--Cont	char	13
,''	--Grupa	char	13
,''	--Valuta	char	3
,0	--Pret_in_valuta	float	8
,0	--Pret_stoc	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[pret aman RON cu TVA]),',',''))*1.24	--Pret_vanzare	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[pret aman RON cu TVA]),',',''))	--Pret_cu_amanuntul	float	8
,24	--Cota_TVA	real	4
,0	--Stoc_limita	float	8
,0	--Stoc	float	8
,0	--Greutate_specifica	float	8
,max(s.Brand)	--Furnizor	char	13
,CASE WHEN len(rtrim(s.Cod))>20	THEN LEFT(s.Cod,30) ELSE '' END --Loc_de_munca	char	150
,''--LEFT(MAX('212'),20)	--Gestiune	char	13
,'4'	--Categorie	smallint	2
,''	--Tip_echipament	char	21
		-- SELECT *
FROM PRETURI_MAGAZIN1 s
--JOIN CONTGESTSTOCURIMPL C ON S.cont=C.CONT
--JOIN gestiuni G ON G.Cod_gestiune='212'
--where len(rtrim(s.Cod)) <=20
GROUP BY s.Cod --,s.[pret_intrare fara TVA],s.[pret_vanzare fara TVA],s.[pret_vanzare_cu TVA ],s.data_intrare

--insert nomencl_coduri_mari
select *,'' from STOC_MAGAZIN_CODURI_LIPSA s
where LEN(cod)>20

--update STOC_MAGAZIN_CODURI_LIPSA
set Cod=codnou
from STOC_MAGAZIN_CODURI_LIPSA p join nomencl_coduri_mari n on n.Cod=p.Cod

--insert nomencl
select * from STOC_MAGAZIN_CODURI_LIPSA s where s.Cod not in (select n.cod from nomencl n)
-- delete nomencl
from nomencl n join STOC_MAGAZIN_CODURI_LIPSA s on s.cod=n.cod
--where s.Cod not in (select n.cod from nomencl n)

-- update nomencl
set furnizor=s.furnizor
from nomencl n join STOC_MAGAZIN_CODURI_LIPSA s on s.cod=n.cod
where n.furnizor=''


--insert nomencl
--SELECT
--      [Cod]
--      ,[Tip]
--      ,[Denumire]
--      ,[UM]
--      ,[UM_1]
--      ,[Coeficient_conversie_1]
--      ,[UM_2]
--      ,[Coeficient_conversie_2]
--      ,[Cont]
--      ,[Grupa]
--      ,[Valuta]
--      ,[Pret_in_valuta]
--      ,[Pret_stoc]
--      ,[Pret_vanzare]
--      ,[Pret_cu_amanuntul]
--      ,[Cota_TVA]
--      ,[Stoc_limita]
--      ,[Stoc]
--      ,[Greutate_specifica]
--      ,[Furnizor]
--      ,[Loc_de_munca]
--      ,[Gestiune]
--      ,[Categorie]
--      ,[Tip_echipament]


-- from syssn s where s.Stergator='OVIDIU' and s.Data_stergerii ='2012-02-29 11:23:38.730'

select * 
INTO PRETURI_DISTRIB_MARFA_ASIS
from PRETURI

alter table PRETURI_DISTRIB_MARFA_ASIS alter column cod_produs char(25) not null

---- TRUNCATE TABLE PRETURI_DISTRIB_MARFA_ASIS INSERT PRETURI_DISTRIB_MARFA_ASIS
SELECT --*, 
LEFT(isnull(n.codnou, p.cod) ,25) --Cod_produs	char	no	30	     
,3 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,'2012-01-01' --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,MAX(CONVERT(FLOAT,REPLACE(P.[PC MARTIE 2012 RON],',','')))--Pret_vanzare	float	no	8	53   
,0--MAX(CONVERT(FLOAT,REPLACE(P.[PC MARTIE 2012 RON],',','')))--Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT MAX(LEN(COD))
--TOP 300 cod, max(P.[pret aman RON cu TVA]) 
FROM PRETURI_DISTRIB_MARFA p
left join nomencl_coduri_mari n on n.cod=p.cod
--where len(cod)>20 --and cod='00630101'
group by isnull(n.codnou, p.cod)

select * from PRETURI_DISTRIB_MARFA_ASIS p where len(p.Cod_produs)>20 and p.Cod_produs not in 
(select n.cod from nomencl_coduri_mari n)

--update PRETURI_DISTRIB_MARFA_ASIS
set Cod_produs=codnou
from PRETURI_DISTRIB_MARFA_ASIS p join nomencl_coduri_mari n on n.Cod=p.Cod_produs


select * from PRETURI_DISTRIB_MARFA_ASIS p where len(p.Cod_produs)>20 and 
p.Cod_produs not in 
(select n.cod from nomencl n)

-- INSERT PRETURI
SELECT * FROM PRETURI_DISTRIB_MARFA_ASIS P
WHERE NOT EXISTS (select 1 from preturi pt where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret)

-- UPDATE preturi
set Pret_vanzare=pt.Pret_vanzare
,Pret_cu_amanuntul=pt.Pret_cu_amanuntul
from preturi p join PRETURI_DISTRIB_MARFA_ASIS pt on pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret

select TOP 0 *
into PRETURI_DISTRIB_MARFA_CODURI_LIPSA
FROM NOMENCL
ALTER TABLE #TEMPTEST 
ALTER COLUMN COD CHAR(35) NOT NULL

SET ANSI_WARNINGS OFF
-- TRUNCATE TABLE PRETURI_DISTRIB_MARFA_CODURI_LIPSA INSERT PRETURI_DISTRIB_MARFA_CODURI_LIPSA
-- INSERT #TEMPTEST
--SELECT * FROM PRETURI_DISTRIB_MARFA_CODURI_LIPSA
--EXCEPT
SELECT --*,
LEFT(isnull(n.codnou,s.cod),25)	--Cod	char	30
,'M'	--Tip	char	1
,LEFT(MAX(S.[Denumirea produsului]),150)	--Denumire	char	150
,LEFT(MAX(S.UM),3)	--UM	char	3
,''	--UM_1	char	3
,0	--Coeficient_conversie_1	float	8
,''	--UM_2	char	20
,0	--Coeficient_conversie_2	float	8
,LEFT('371.1',13)	--Cont	char	13
,''	--Grupa	char	13
,''	--Valuta	char	3
,0	--Pret_in_valuta	float	8
,0	--Pret_stoc	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[PC MARTIE 2012 RON]),',',''))	--Pret_vanzare	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[PC MARTIE 2012 RON]),',',''))*1.24	--Pret_cu_amanuntul	float	8
,24	--Cota_TVA	real	4
,0	--Stoc_limita	float	8
,0	--Stoc	float	8
,0	--Greutate_specifica	float	8
,LEFT(MAX(s.Brand),13)	--Furnizor	char	13
,CASE WHEN len(rtrim(max(s.Cod)))>20	THEN LEFT(max(s.Cod),30) ELSE '' END --Loc_de_munca	char	150
,''--LEFT(MAX('212'),20)	--Gestiune	char	13
,'4'	--Categorie	smallint	2
,''	--Tip_echipament	char	21
		-- SELECT max(len(cod))
--INTO #TEMPTEST
FROM PRETURI_DISTRIB_MARFA s
left join nomencl_coduri_mari n on n.cod=s.cod
--JOIN CONTGESTSTOCURIMPL C ON S.cont=C.CONT
--JOIN gestiuni G ON G.Cod_gestiune='212'
--where len(rtrim(s.Cod)) <=20
GROUP BY isnull(n.codnou,s.cod) --,s.[pret_intrare fara TVA],s.[pret_vanzare fara TVA],s.[pret_vanzare_cu TVA ],s.data_intrare
--SET ANSI_WARNINGS ON

select * from PRETURI_DISTRIB_MARFA_CODURI_LIPSA p where len(p.COD)>20 and p.COD not in 
(select n.cod from nomencl_coduri_mari n)

-- insert nomencl
select * from PRETURI_DISTRIB_MARFA_CODURI_LIPSA s where s.Cod not in (select n.cod from nomencl n)

select * 
INTO PRETURI_DISTRIB_PIESE_ASIS
from PRETURI

--alter table PRETURI_DISTRIB_PIESE_ASIS alter column cod_produs char(25) not null

---- TRUNCATE TABLE PRETURI_DISTRIB_PIESE_ASIS INSERT PRETURI_DISTRIB_PIESE_ASIS
SELECT --*, 
LEFT(isnull(n.codnou, p.cod) ,25) --Cod_produs	char	no	30	     
,3 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,'2012-01-01' --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,MAX(CONVERT(FLOAT,REPLACE(P.[PC MARTIE 2012 RON],',','')))--Pret_vanzare	float	no	8	53   
,0--MAX(CONVERT(FLOAT,REPLACE(P.[PC MARTIE 2012 RON],',','')))--Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT MAX(LEN(p.cod))
--TOP 300 cod, max(P.[pret aman RON cu TVA]) 
FROM PRETURI_DISTRIB_PIESE p
left join nomencl_coduri_mari n on n.cod=p.cod
--where len(cod)>20 --and cod='00630101'
group by isnull(n.codnou, p.cod)

select * from PRETURI_DISTRIB_PIESE_ASIS p where len(p.Cod_produs)>20 and p.Cod_produs not in 
(select n.cod from nomencl_coduri_mari n)

--update PRETURI_DISTRIB_MARFA_ASIS
set Cod_produs=codnou
from PRETURI_DISTRIB_PIESE_ASIS p join nomencl_coduri_mari n on n.Cod=p.Cod_produs


select * from PRETURI_DISTRIB_PIESE_ASIS p where --len(p.Cod_produs)>20 and 
p.Cod_produs not in 
(select n.cod from nomencl n)

-- INSERT PRETURI
SELECT * FROM PRETURI_DISTRIB_PIESE_ASIS P
WHERE NOT EXISTS (select 1 from preturi pt where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret)

-- UPDATE preturi
set Pret_vanzare=pt.Pret_vanzare
,Pret_cu_amanuntul=pt.Pret_cu_amanuntul
from preturi p join PRETURI_DISTRIB_PIESE_ASIS pt on pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret

select TOP 0 *
into PRETURI_DISTRIB_PIESE_CODURI_LIPSA
FROM NOMENCL
ALTER TABLE #TEMPTEST 
ALTER COLUMN COD CHAR(35) NOT NULL

SET ANSI_WARNINGS OFF
-- TRUNCATE TABLE PRETURI_DISTRIB_PIESE_CODURI_LIPSA INSERT PRETURI_DISTRIB_PIESE_CODURI_LIPSA
-- INSERT #TEMPTEST
--SELECT * FROM PRETURI_DISTRIB_MARFA_CODURI_LIPSA
--EXCEPT
SELECT --*,
ltrim(rtrim(LEFT(isnull(n.codnou,s.cod),25)))	--Cod	char	30
,'M'	--Tip	char	1
,LEFT(MAX(S.[Denumire produs]),150)	--Denumire	char	150
,LEFT(MAX(S.UM),3)	--UM	char	3
,''	--UM_1	char	3
,0	--Coeficient_conversie_1	float	8
,''	--UM_2	char	20
,0	--Coeficient_conversie_2	float	8
,LEFT('371.1',13)	--Cont	char	13
,''	--Grupa	char	13
,''	--Valuta	char	3
,0	--Pret_in_valuta	float	8
,0	--Pret_stoc	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[PC MARTIE 2012 RON]),',',''))	--Pret_vanzare	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[PC MARTIE 2012 RON]),',',''))*1.24	--Pret_cu_amanuntul	float	8
,24	--Cota_TVA	real	4
,0	--Stoc_limita	float	8
,0	--Stoc	float	8
,0	--Greutate_specifica	float	8
,LEFT(MAX(s.Brand),13)	--Furnizor	char	13
,CASE WHEN len(rtrim(max(s.Cod)))>20	THEN LEFT(max(s.Cod),30) ELSE '' END --Loc_de_munca	char	150
,''--LEFT(MAX('212'),20)	--Gestiune	char	13
,'4'	--Categorie	smallint	2
,''	--Tip_echipament	char	21
		-- SELECT max(len(cod))
--INTO #TEMPTEST
FROM PRETURI_DISTRIB_PIESE s
left join nomencl_coduri_mari n on n.cod=s.cod
--JOIN CONTGESTSTOCURIMPL C ON S.cont=C.CONT
--JOIN gestiuni G ON G.Cod_gestiune='212'
--where len(rtrim(s.Cod)) <=20
GROUP BY isnull(n.codnou,s.cod) --,s.[pret_intrare fara TVA],s.[pret_vanzare fara TVA],s.[pret_vanzare_cu TVA ],s.data_intrare
--SET ANSI_WARNINGS ON

select * from PRETURI_DISTRIB_PIESE p where p.Cod like '%MUS%'

select * from PRETURI_DISTRIB_MARFA_CODURI_LIPSA p where len(p.COD)>20 and p.COD not in 
(select n.cod from nomencl_coduri_mari n)



-- insert nomencl
select * from PRETURI_DISTRIB_PIESE_CODURI_LIPSA s where s.Cod not in (select n.cod from nomencl n)

select * 
INTO PRETURI_MAGAZIN_MARTIE_ASIS
from PRETURI

alter table PRETURI_MAGAZIN_MARTIE_ASIS alter column cod_produs char(25) not null

---- TRUNCATE TABLE PRETURI_MAGAZIN_MARTIE_ASIS INSERT PRETURI_MAGAZIN_MARTIE_ASIS
SELECT --*, 
max(LEFT(isnull(n.codnou, p.cod) ,25)) --Cod_produs	char	no	30	     
,4 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,'2012-01-01' --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,MAX(CONVERT(FLOAT,REPLACE(P.[pret vanzare amanunt in RON fara TVA, incepand cu 1 martie 2012],',','')))--Pret_vanzare	float	no	8	53   
,MAX(CONVERT(FLOAT,REPLACE(P.[PCF, RON, cu TVA (martie) ],',','')))--Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT max(len(cod))
--TOP 300 cod, max(P.[pret aman RON cu TVA]) 
FROM PRETURI_MAGAZIN_MARTIE p
left join nomencl_coduri_mari n on n.cod=p.cod
where p.cod<>'' 
--len(cod)>20 
--and cod='00630101'
group by isnull(n.codnou, p.cod)

select * from PRETURI_MAGAZIN_MARTIE_ASIS p where len(p.Cod_produs)>20 and p.Cod_produs not in 
(select n.cod from nomencl_coduri_mari n)

select n.Denumire,p.* 
INTO PRETURI_MAGAZIN_MARTIE_ASIS_vechi_neactualizate
from preturi P join nomencl n on n.Cod=p.Cod_produs
WHERE NOT EXISTS (select 1 from PRETURI_MAGAZIN_MARTIE_ASIS pt where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret)
and p.UM=4 and p.Tip_pret='1'

-- UPDATE preturi
set Pret_vanzare=pt.Pret_vanzare
,Pret_cu_amanuntul=pt.Pret_cu_amanuntul
from preturi p join PRETURI_MAGAZIN_MARTIE_ASIS pt on pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret

--INSERT preturi
select * from PRETURI_MAGAZIN_MARTIE_ASIS P
WHERE NOT EXISTS (select 1 from preturi pt where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret)

SELECT Cod_produs, UM, Tip_pret, Data_inferioara, Ora_inferioara, Ora_superioara, Ora_operarii
FROM PRETURI_MAGAZIN_ULTIM
GROUP BY Cod_produs, UM, Tip_pret, Data_inferioara, Ora_inferioara, Ora_superioara, Ora_operarii
HAVING COUNT(*)>1

--update PRETURI_MAGAZIN_ULTIM
set Cod_produs=codnou
from PRETURI_MAGAZIN_ULTIM p join nomencl_coduri_mari n on n.Cod=p.Cod_produs

SELECT *
--TOP 300 cod, max(P.[pret aman RON cu TVA]) 
FROM PRETURI_MAGAZIN_ULTIM p
where cod_produs='00630101'
where len(cod_produs)>20

select n.Denumire, p.* from preturi P join nomencl n on p.Cod_produs=n.Cod
WHERE EXISTS (select 1 from PRETURI_MAGAZIN_ULTIM pt 
where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret) 
and exists (select 1 from PRETURI_MAGAZIN_ULTIM pt 
where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret 
and pt.Pret_vanzare<>p.Pret_vanzare and pt.Pret_cu_amanuntul<>p.Pret_cu_amanuntul)

--UPDATE preturi
set Pret_vanzare=pt.Pret_vanzare
,Pret_cu_amanuntul=pt.Pret_cu_amanuntul
from preturi p join PRETURI_MAGAZIN_ULTIM pt on pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret

select TOP 0 *
into PRETURI_MAGAZIN_MARTIE_CODURI_LIPSA
FROM NOMENCL
ALTER TABLE PRETURI_MAGAZIN_MARTIE_CODURI_LIPSA 
ALTER COLUMN COD CHAR(25) NOT NULL

-- TRUNCATE TABLE PRETURI_MAGAZIN_MARTIE_CODURI_LIPSA INSERT PRETURI_MAGAZIN_MARTIE_CODURI_LIPSA
SELECT --*,
LEFT(isnull(n.codnou, S.cod),30)	--Cod	char	30
,'M'	--Tip	char	1
,LEFT(MAX(S.[Denumirea produsului]),150)	--Denumire	char	150
,LEFT(MAX(S.UM),3)	--UM	char	3
,''	--UM_1	char	3
,0	--Coeficient_conversie_1	float	8
,''	--UM_2	char	20
,0	--Coeficient_conversie_2	float	8
,LEFT('371.1',13)	--Cont	char	13
,''	--Grupa	char	13
,''	--Valuta	char	3
,0	--Pret_in_valuta	float	8
,0	--Pret_stoc	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[pret vanzare amanunt in RON fara TVA, incepand cu 1 martie 2012]),',',''))	--Pret_vanzare	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[PCF, RON, cu TVA (martie) ]),',',''))	--Pret_cu_amanuntul	float	8
,24	--Cota_TVA	real	4
,0	--Stoc_limita	float	8
,0	--Stoc	float	8
,0	--Greutate_specifica	float	8
,left(max(s.Brand),13)	--Furnizor	char	13
,CASE WHEN len(rtrim(max(s.Cod)))>20	THEN LEFT(max(s.Cod),30) ELSE '' END --Loc_de_munca	char	150
,''--LEFT(MAX('212'),20)	--Gestiune	char	13
,'4'	--Categorie	smallint	2
,''	--Tip_echipament	char	21
		-- SELECT max(len(cod))
FROM PRETURI_MAGAZIN_MARTIE s
left join nomencl_coduri_mari n on n.cod=S.cod
where S.cod<>'' 
--len(cod)>20 
--and cod='00630101'
group by isnull(n.codnou, S.cod)

--insert nomencl_coduri_mari
select *,'' from PRETURI_MAGAZIN_MARTIE_CODURI_LIPSA s
where LEN(cod)>20

--update STOC_MAGAZIN_CODURI_LIPSA
set Cod=codnou
from PRETURI_MAGAZIN_MARTIE_CODURI_LIPSA p join nomencl_coduri_mari n on n.Cod=p.Cod

--insert nomencl
select * from PRETURI_MAGAZIN_MARTIE_CODURI_LIPSA s where s.Cod not in (select n.cod from nomencl n)
-- delete nomencl
from nomencl n join STOC_MAGAZIN_CODURI_LIPSA s on s.cod=n.cod
--where s.Cod not in (select n.cod from nomencl n)

-- update nomencl
set furnizor=s.furnizor
from nomencl n join STOC_MAGAZIN_CODURI_LIPSA s on s.cod=n.cod
where n.furnizor=''

select * from preturi pr where pr.UM='1'

update preturi
set UM='11'
from preturi pr where pr.UM='1'

update preturi
set UM='13'
from preturi pr where pr.UM='3'

update preturi
set UM='1'
from preturi pr where pr.UM='13'

update preturi
set UM='3'
from preturi pr where pr.UM='11'

select * 
--INTO PRETURI_PRETURI_PACHETE
from PRETURI

alter table PRETURI_MAGAZIN_MARTIE_ASIS alter column cod_produs char(25) not null

---- TRUNCATE TABLE PRETURI_PRETURI_PACHETE INSERT PRETURI_PRETURI_PACHETE
SELECT --*, 
max(LEFT(isnull(P.Cod, p.cod) ,20)) --Cod_produs	char	no	30	     
,1 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,'2012-01-01' --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,MAX(CONVERT(FLOAT,REPLACE(P.[Pret de catalog TRUST ron, fara tva ],',','')))--Pret_vanzare	float	no	8	53   
,MAX(CONVERT(FLOAT,REPLACE(P.[Pret de client final (magazine) ron, cu tva inclus],',','')))--Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT max(len(cod))
--TOP 300 cod, max(P.[pret aman RON cu TVA]) 
FROM PRETURI_PACHETE p
--left join nomencl_coduri_mari n on n.cod=p.cod
where p.cod<>'' 
--len(cod)>20 
--and cod='00630101'
group by isnull(p.COD, p.cod)

-- INSERT PRETURI_PRETURI_PACHETE
SELECT --*, 
max(LEFT(isnull(P.Cod, p.cod) ,20)) --Cod_produs	char	no	30	     
,4 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,'2012-01-01' --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,MAX(CONVERT(FLOAT,REPLACE(P.[Pret de catalog TRUST ron, fara tva ],',','')))--Pret_vanzare	float	no	8	53   
,MAX(CONVERT(FLOAT,REPLACE(P.[Pret de client final (magazine) ron, cu tva inclus],',','')))--Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT max(len(cod))
--TOP 300 cod, max(P.[pret aman RON cu TVA]) 
FROM PRETURI_PACHETE p
--left join nomencl_coduri_mari n on n.cod=p.cod
where p.cod<>'' 
--len(cod)>20 
--and cod='00630101'
group by isnull(p.COD, p.cod)

select *
-- UPDATE preturi set Pret_vanzare=pt.Pret_vanzare,Pret_cu_amanuntul=pt.Pret_cu_amanuntul
from preturi p join PRETURI_PRETURI_PACHETE pt on pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret

--INSERT preturi
select * from PRETURI_PRETURI_PACHETE P
WHERE NOT EXISTS (select 1 from preturi pt where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret)

select * 
INTO PRETURI_PRETURI_ERATA_APRILIE
from PRETURI

-- TRUNCATE TABLE PRETURI_PRETURI_ERATA_APRILIE INSERT PRETURI_PRETURI_ERATA_APRILIE
SELECT --*, 
max(LEFT(isnull(P.Cod, p.cod) ,20)) --Cod_produs	char	no	30	     
,4 --UM	smallint	no	2	5    
,'1' --Tip_pret	char	no	20	     
,'2012-01-01' --Data_inferioara	datetime	no	8	     
,'' --Ora_inferioara	char	no	13	     
,'2998-01-01' --Data_superioara	datetime	no	8	     
,'' --Ora_superioara	char	no	6	     
,MAX(ROUND(CONVERT(FLOAT,REPLACE(P.[Pret client final, ron, cu tva inclus],',',''))/1.24,2))--Pret_vanzare	float	no	8	53   
,MAX(CONVERT(FLOAT,REPLACE(P.[Pret client final, ron, cu tva inclus],',','')))--Pret_cu_amanuntul	float	no	8	53   
,'IMPL' --Utilizator	char	no	10	     
,GETDATE() --Data_operarii	datetime	no	8	     
,'' --Ora_operarii	char	no	6	     
-- SELECT *
--TOP 300 cod, max(P.[pret aman RON cu TVA]) 
FROM PRETURI_ERATA_APRILIE p
--left join nomencl_coduri_mari n on n.cod=p.cod
where p.cod<>'' 
--len(cod)>20 
--and cod='00630101'
group by isnull(p.COD, p.cod)

select *
-- UPDATE preturi set Pret_vanzare=pt.Pret_vanzare,Pret_cu_amanuntul=pt.Pret_cu_amanuntul
from preturi p join PRETURI_PRETURI_ERATA_APRILIE pt on pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret

--INSERT preturi
select * from PRETURI_PRETURI_ERATA_APRILIE P
WHERE NOT EXISTS (select 1 from preturi pt where pt.Cod_produs=p.Cod_produs and pt.UM=p.UM and pt.Tip_pret=p.Tip_pret)