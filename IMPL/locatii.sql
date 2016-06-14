select * from LOCATORI
select * from locatii


----INSERT locatii
select DISTINCT
LEFT(locator,13)	--Cod_locatie	char	13
,0	--Este_grup	bit	1
,''	--Cod_grup	char	13
,''	--UM	char	3
,0	--Capacitate	float	8
,LEFT(GESTIUNE,9)	--Cod_gestiune	char	9
,0	--Incarcare	bit	1
,1	--Nivel	smallint	2
,LEFT(LOCATOR,30)	--Descriere	char	30
from LOCATORI
order by LEFT(locator,13)

SELECT LOCATOR 
FROM LOCATORI L
GROUP BY LOCATOR

SELECT * FROM LOCATORI
WHERE ARTICOL =''

SELECT TOP 0 * 
INTO LOCATORI_PROPRIETATI
FROM PROPRIETATI

--TRUNCATE TABLE LOCATORI_PROPRIETATI
--INSERT LOCATORI_PROPRIETATI
SELECT DISTINCT --*,
'NOMENCL'	--Tip	char	no	20
,LEFT(L.ARTICOL,20)	--Cod	char	no	30
,'LOCATOR'	--Cod_proprietate	char	no	20
,LEFT(L.LOCATOR,200)	--Valoare	char	no	200
,''	--Valoare_tupla	char	no	200
FROM LOCATORI L

--DELETE proprietati
where Cod_proprietate='LOCATOR'

--INSERT proprietati
select * from LOCATORI_PROPRIETATI

select * from LOCATORI_PROPRIETATI
WHERE COD NOT IN (select cod from nomencl)

select TOP 0 *
into LOCATORI_NOMENCL_LIPSA
from nomencl

--INSERT LOCATORI_NOMENCL_LIPSA
select
LEFT(l.ARTICOL,20)	--Cod	char	no	30
,'M'	--Tip	char	no	1
,LEFT(L.DESCRIERE,150)	--Denumire	char	no	150
,'BUC'	--UM	char	no	3
,''	--UM_1	char	no	3
,0	--Coeficient_conversie_1	float	no	8
,''	--UM_2	char	no	20
,0	--Coeficient_conversie_2	float	no	8
,'371.1'	--Cont	char	no	13
,''	--Grupa	char	no	13
,''	--Valuta	char	no	3
,0	--Pret_in_valuta	float	no	8
,0	--Pret_stoc	float	no	8
,0	--Pret_vanzare	float	no	8
,0	--Pret_cu_amanuntul	float	no	8
,24	--Cota_TVA	real	no	4
,0	--Stoc_limita	float	no	8
,0	--Stoc	float	no	8
,0	--Greutate_specifica	float	no	8
,''	--Furnizor	char	no	13
,''	--Loc_de_munca	char	no	150
,'101'	--Gestiune	char	no	13
,''	--Categorie	smallint	no	2
,''	--Tip_echipament	char	no	21
	-- SELECT *
FROM LOCATORI l

--INSERT nomencl
select * from LOCATORI_NOMENCL_LIPSA l 
where l.Cod not in (select cod from nomencl n)

select top 0 *
into STOCLIM_LOCATORI
from stoclim

--TRUNCATE TABLE STOCLIM_LOCATORI                   
----INSERT STOCLIM_LOCATORI
SELECT DISTINCT --*,
'1'	--Subunitate	char	9
,'C'	--Tip_gestiune	char	1
,LEFT(L.GESTIUNE,9)	--Cod_gestiune	char	9
,LEFT(l.ARTICOL,20)	--Cod	char	20
,'2999-12-31'	--Data	datetime	8
,0	--Stoc_min	float	8
,0	--Stoc_max	float	8
,0	--Pret	float	8
,LEFT(L.LOCATOR,30)	--Locatie	char	30
	-- SELECT MAX(LEN(COD))
FROM LOCATORI L


--TRUNCATE TABLE STOCLIM
--INSERT stoclim
SELECT * FROM STOCLIM_LOCATORI  

SELECT Subunitate, Tip_gestiune, Cod_gestiune, Cod, Data 
FROM STOCLIM_LOCATORI
GROUP BY Subunitate, Tip_gestiune, Cod_gestiune, Cod, Data
HAVING COUNT(*)>1

select gestiunea,locator from 
(select l.gestiunea,l.locator from locatori_final l
group by l.gestiunea,l.locator) d
group by d.GESTIUNEA,d.LOCATOR
having COUNT(*)>1

-----------------------------------------------------------

-- TRUNCATE TABLE LOCATII INSERT locatii
select 
LEFT(locator,13)	--Cod_locatie	char	13
,0	--Este_grup	bit	1
,''	--Cod_grup	char	13
,''	--UM	char	3
,0	--Capacitate	float	8
,LEFT(L.GESTIUNEA,9)	--Cod_gestiune	char	9
,0	--Incarcare	bit	1
,1	--Nivel	smallint	2
,max(LEFT(L.LOCATOR,30))	--Descriere	char	30
from LOCATORI_FINAL L
group by l.GESTIUNEA,l.LOCATOR

SELECT LOCATOR 
FROM LOCATORI L
GROUP BY LOCATOR

SELECT * FROM LOCATORI
WHERE ARTICOL =''

SELECT TOP 0 * 
INTO LOCATORI_PROPRIETATI
FROM PROPRIETATI

--TRUNCATE TABLE LOCATORI_PROPRIETATI
--INSERT LOCATORI_PROPRIETATI
SELECT DISTINCT --*,
'NOMENCL'	--Tip	char	no	20
,LEFT(L.ARTICOL,20)	--Cod	char	no	30
,'LOCATOR'	--Cod_proprietate	char	no	20
,LEFT(L.LOCATOR,200)	--Valoare	char	no	200
,''	--Valoare_tupla	char	no	200
FROM LOCATORI L

--DELETE proprietati
where Cod_proprietate='LOCATOR'

--INSERT proprietati
select * from LOCATORI_PROPRIETATI

select * from LOCATORI_PROPRIETATI
WHERE COD NOT IN (select cod from nomencl)

select TOP 0 *
into LOCATORI_FINAL_NOMENCL_LIPSA
from nomencl

--INSERT LOCATORI_FINAL_NOMENCL_LIPSA
select
LEFT(l.ARTICOL,20)	--Cod	char	no	30
,'M'	--Tip	char	no	1
,MAX(LEFT(L.DESCRIPTION,150))	--Denumire	char	no	150
,'BUC'	--UM	char	no	3
,''	--UM_1	char	no	3
,0	--Coeficient_conversie_1	float	no	8
,''	--UM_2	char	no	20
,0	--Coeficient_conversie_2	float	no	8
,'371.1'	--Cont	char	no	13
,''	--Grupa	char	no	13
,''	--Valuta	char	no	3
,0	--Pret_in_valuta	float	no	8
,0	--Pret_stoc	float	no	8
,0	--Pret_vanzare	float	no	8
,0	--Pret_cu_amanuntul	float	no	8
,24	--Cota_TVA	real	no	4
,0	--Stoc_limita	float	no	8
,0	--Stoc	float	no	8
,0	--Greutate_specifica	float	no	8
,''	--Furnizor	char	no	13
,''	--Loc_de_munca	char	no	150
,'101'	--Gestiune	char	no	13
,''	--Categorie	smallint	no	2
,''	--Tip_echipament	char	no	21
	-- SELECT *
FROM LOCATORI_FINAL l
GROUP BY L.ARTICOL

--INSERT nomencl
select * from LOCATORI_FINAL_NOMENCL_LIPSA l 
where l.Cod not in (select cod from nomencl n)

select top 0 *
into STOCLIM_LOCATORI_FINAL
from stoclim

-- TRUNCATE TABLE STOCLIM_LOCATORI_FINAL INSERT STOCLIM_LOCATORI_FINAL
SELECT  --*,
'1'	--Subunitate	char	9
,'C'	--Tip_gestiune	char	1
,LEFT(L.GESTIUNEA,9)	--Cod_gestiune	char	9
,LEFT(l.ARTICOL,20)	--Cod	char	20
,'2999-12-31'	--Data	datetime	8
,0	--Stoc_min	float	8
,0	--Stoc_max	float	8
,0	--Pret	float	8
,max(LEFT(L.LOCATOR,30))	--Locatie	char	30
	-- SELECT MAX(LEN(COD))
FROM LOCATORI_FINAL L
GROUP BY L.GESTIUNEA,L.ARTICOL--,L.LOCATOR
--having COUNT(distinct l.locator)<=9

-- INSERT STOCLIM_LOCATORI_FINAL
SELECT  --*,
'1'	--Subunitate	char	9
,'C'	--Tip_gestiune	char	1
,LEFT(L.Cod_gestiune,9)	--Cod_gestiune	char	9
,LEFT(l.Cod,20)	--Cod	char	20
,'2999-12-31'	--Data	datetime	8
,0	--Stoc_min	float	8
,0	--Stoc_max	float	8
,0	--Pret	float	8
,max(LEFT(L.Locatie,30))	--Locatie	char	30
	-- SELECT MAX(LEN(COD))
FROM STOCLIM_LOCATORI_FINAL L
GROUP BY L.Cod_gestiune,L.cod,L.Locatie
having COUNT(l.Locatie) over(partition by l.cod_gestiune,l.locatie)<=9


select * from stoclim
--DELETE STOCLIM where data='2999-12-31' INSERT stoclim
SELECT * FROM STOCLIM_LOCATORI_FINAL  S WHERE S.Locatie LIKE '%LIVR%'

SELECT Subunitate, Tip_gestiune, Cod_gestiune, Cod, Data 
FROM STOCLIM_LOCATORI
GROUP BY Subunitate, Tip_gestiune, Cod_gestiune, Cod, Data
HAVING COUNT(*)>1

select gestiunea,articol from 
(select l.gestiunea,l.ARTICOL, l.locator from locatori_final l
group by l.gestiunea,l.ARTICOL, l.locator ) d
group by d.GESTIUNEA,d.LOCATOR
having COUNT(*)>1

select l.gestiunea,l.ARTICOL,COUNT(distinct l.locator) from locatori_final l
group by l.gestiunea,l.ARTICOL
having COUNT(distinct l.locator)>1
order by COUNT(distinct l.locator) desc

SELECT * FROM LOCATORI_FINAL l where l.ARTICOL='BST-RADET16'
BST-RFMM34
BST-RFTM34
BST-RMMM112
BST-C060408
BST-CRB061604
BST-CRR061604
BST-RADER16
--insert stoclim
select 
Subunitate
,Tip_gestiune
,'900'
,Cod
,Data
,Stoc_min
,Stoc_max
,Pret
,Locatie
from stoclim sl where sl.data='2999-12-31' and sl.cod_gestiune='101' 
and not exists 
(select Subunitate, Tip_gestiune, Cod_gestiune, Cod, Data 
from stoclim sl1 where sl1.Cod_gestiune='900' and sl.Cod=sl1.Cod and sl.Data=sl1.Data)

select * from stoclim s where s.Locatie not in (select l.cod_locatie from locatii l where l.Cod_gestiune=s.Cod_gestiune)
select * from stoclim s where s.Locatie like '%LIVR%'

select sl1.*
-- update sl set locatie=sl1.locatie
from stoclim sl join STOCLIM_LOCATORI_FINAL sl1 on sl1.Cod_gestiune=sl.Cod_gestiune and sl.Cod=sl1.Cod and sl.Data=sl1.Data
where sl.data='2999-12-31' --and sl.cod_gestiune='900' 
and sl.locatie<>sl1.locatie

select sl1.*
-- update sl1 set locatie=sl.locatie
from stoclim sl join stoclim sl1 on sl.Cod_gestiune='900' and sl1.Cod_gestiune='101' and sl.Cod=sl1.Cod and sl.Data=sl1.Data
where sl.data='2999-12-31' 
and sl.locatie<>sl1.locatie

--insert locatii
select 
left(l.Locatie,13)	--Cod_locatie
,0	--,Este_grup
,''	--,Cod_grup
,''	--,UM
,0	--,Capacitate
,l.Cod_gestiune	--,l.Cod_gestiune
,0	--,Incarcare
,1	--,Nivel
,l.locatie	--,Descriere
-- select Cod_gestiune, locatie
 from stoclim l where l.data='2999-12-31' and not exists
 (select 1 from locatii l1 where l.Cod_gestiune=l1.cod_gestiune and left(l.Locatie,13)=l1.Cod_locatie)
 GROUP BY Cod_gestiune, locatie
having COUNT(*)>1

select * from stoclim s where s.Data='2999-12-31' and s.Cod_gestiune= '212' and s.Locatie='Locator Pct Lucru CJ'          

--insert locatii
select 
Cod_locatie
,Este_grup
,Cod_grup
,UM
,Capacitate
,'900'
,Incarcare
,Nivel
,Descriere
 from locatii l where Cod_gestiune='101' and l.Cod_locatie not in 
 (select l1.cod_locatie from locatii l1 where l1.Cod_gestiune='900')
 
 select * from debug..stoclim s where s.cod='100-ISO4-16-BL'