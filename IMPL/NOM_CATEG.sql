--
EROARE

----TRUNCATE TABLE NOMENCLidx
----INSERT NOMENCLidx
SELECT 
LEFT(COD,30)--Cod	char	no	20	     
,CASE CATEG_CONTABILA 
	WHEN 'Marfuri' THEN CASE WHEN GRUPA_VANZARE LIKE '%pachet%' THEN 'P' ELSE 'M' END 
	WHEN 'Promotionale' THEN 'M' WHEN 'Piese schimb' THEN 'M' ELSE '' END--Tip	char	no	1	     
,LEFT(DENUMIRE,150)--Denumire	char	no	80	     
,LEFT(COD_UNIT_MAS,3)--UM	char	no	3	     
,''--UM_1	char	no	3	     
,0--Coeficient_conversie_1	float	no	8	53   
,''--UM_2	char	no	20	     
,0--Coeficient_conversie_2	float	no	8	53   
,CASE CONT_VENIT WHEN '7080' THEN '380' WHEN '7071' THEN '3711' WHEN '7072' THEN '3712' ELSE LEFT(CONT_VENIT,13) END--Cont	char	no	13	     
,LEFT((SELECT MAX(CODGRUPAVANZARE) FROM GRUPE_VANZARE WHERE GRUPA_VANZARE LIKE NOM_CATEG.GRUPA_VANZARE),13)--Grupa	char	no	13	     
,''--Valuta	char	no	3	     
,0--Pret_in_valuta	float	no	8	53   
,0--Pret_stoc	float	no	8	53   
,0--Pret_vanzare	float	no	8	53   
,0--Pret_cu_amanuntul	float	no	8	53   
,24--Cota_TVA	real	no	4	24   
,0--Stoc_limita	float	no	8	53   
,0--Stoc	float	no	8	53   
,GREUTATEA--Greutate_specifica	float	no	8	53   
,LEFT(COALESCE(RIGHT(REPLACE(REPLACE(RTRIM(FURNIZORI_NOM_CATEG.VAT),' ',''),'.',''),13)
				,RIGHT(REPLACE(REPLACE(RTRIM(FURNIZORI_CON_CLIENTI.CODFISCAL_VAT),' ',''),'.',''),13)
				,NOM_CATEG.FURNIZOR),13)--Furnizor	char	no	13	     
,''--Loc_de_munca	char	no	150	     
,''--Gestiune	char	no	13	     
,0--Categorie	smallint	no	2	5    
,''--Tip_echipament	char	no	21	     
-- SELECT DISTINCT GRUPA_PRODUS,FURNIZOR, GRUPA_VANZARE
FROM NOM_CATEG
LEFT JOIN FURNIZORI_NOM_CATEG ON NOM_CATEG.FURNIZOR=FURNIZORI_NOM_CATEG.FURNIZOR
LEFT JOIN FURNIZORI_CON_CLIENTI ON NOM_CATEG.FURNIZOR=FURNIZORI_CON_CLIENTI.BRAND
--where GRUPA_VANZARE like '%pachet%'

select * from proprietati where Cod_proprietate='ATP'

----INSERT NOMENCLidx
SELECT *
FROM NOMENCLCONIDX
WHERE Cod NOT IN 
(SELECT Cod FROM nomenclidx)

----INSERT nomenclidx
SELECT * FROM NOMENCL_PACHETEARTICOLEIDX
WHERE Cod NOT IN (SELECT COD FROM NOMENCLIDX)

----INSERT nomenclidx
SELECT * FROM NOMENCL_PACHETEIDX
WHERE Cod NOT IN (SELECT Cod FROM nomenclidx)

----INSERT NOMENCLIDX
SELECT * 
FROM NOMENCLPRETIDX
WHERE COD NOT IN 
(SELECT COD FROM NOMENCLIDX)

----TRUNCATE table nomencl
--INSERT nomencl
select * from NOMENCLidx



----UPDATE NOMENCL
SET Valuta=n.valuta,
Pret_in_valuta=n.Pret_in_valuta,
Pret_stoc=n.Pret_stoc,
Pret_vanzare=n.Pret_vanzare,
Categorie=n.Categorie
from nomencl join NOMENCLPRETIDX n on nomencl.Cod=N.cod

SELECT  FURNIZOR, GRUPA_VANZARE 
INTO GRUPE_VANZARE_NOM_CATEG
FROM NOM_CATEG
GROUP BY FURNIZOR, GRUPA_VANZARE
ORDER BY FURNIZOR, GRUPA_VANZARE


select MAX(len(furnizor)) from NOM_CATEG

SELECT DISTINCT CONT_VENIT FROM NOM_CATEG
SELECT DISTINCT GRUPA_PRODUS FROM NOM_CATEG
SELECT * FROM NOM_CATEG WHERE CATEG_CONTABILA='*.*'
SELECT * FROM NOM_CATEG WHERE DENUMIRE LIKE '%REDUCTIE%'


select top 0 *
into nomenclidx
from nomencl

select MAX(len(GRUPA_produs)) from nom_categ
SELECT MAX(LEN(DENUMIRE)) FROM NOM_CATEG
SELECT * FROM NOM_CATEG WHERE LEN(DENUMIRE)>80

SELECT * FROM NOM_CATEG WHERE LEN(COD)>20 ORDER BY COD
(select cod from nom_categ
group by cod
having count(*)>1)

(select cod, COUNT(*) from NOMENCLidx
group by cod
having count(*)>1)

SELECT * FROM NOMENCLidx


grupe
select * from nom_categ

select FURNIZOR,(SELECT MAX(DENUMIRE) FROM TERTI WHERE DENUMIRE LIKE '%'+FURNIZOR+'%')
,(SELECT COUNT(DISTINCT TERT) FROM TERTI WHERE DENUMIRE LIKE '%'+FURNIZOR+'%')
,* from nom_categ
WHERE  (SELECT COUNT(DISTINCT TERT) FROM TERTI WHERE DENUMIRE LIKE '%'+FURNIZOR+'%')>1
ORDER BY NOM_CATEG.FURNIZOR


SELECT N.FURNIZOR, T.Denumire,N.*, T.* 
FROM NOM_CATEG N JOIN TERTI T ON T.Denumire LIKE '%'+LTRIM(RTRIM(N.FURNIZOR))+'%'
ORDER BY N.FURNIZOR, T.Denumire

SELECT DISTINCT FURNIZOR FROM NOM_CATEG

DROP TABLE GRUPEVANZAREIDX
SELECT TOP 0 * 
INTO GRUPEVANZAREIDX
FROM proprietati

----TRUNCATE TABLE GRUPEVANZAREIDX
----INSERT GRUPEVANZAREIDX
SELECT 
'NOMENCL' --Tip	char	no	20	     
,LEFT(COD,30) --Cod	char	no	20	     
,'GRUPAVANZARE' --Cod_proprietate	char	no	20	     
,UPPER(LEFT(GRUPA_VANZARE,200)) --Valoare	char	no	200	     
,'' --Valoare_tupla	char	no	200	 
-- SELECT DISTINCT FURNIZOR, GRUPA_VANZARE    
FROM NOM_CATEG

----INSERT proprietati
--SELECT * FROM GRUPEVANZAREIDX

DROP TABLE VALGRUPEVANZAREIDX
SELECT TOP 0 * 
INTO VALGRUPEVANZAREIDX
FROM VALproprietati

--INSERT VALGRUPEVANZAREIDX
SELECT DISTINCT
'GRUPAVANZARE' --Cod_proprietate	char	no	20
,UPPER(LEFT(GRUPA_PRODUS,200)) --Valoare	char	no	200
,UPPER(LEFT(GRUPA_PRODUS,200)) --Descriere	char	no	80
,'' --Valoare_proprietate_parinte	char	no	200
FROM NOM_CATEG

--DELETE VALproprietati
WHERE Cod_proprietate='GRUPAVANZARE'
--INSERT VALproprietati
SELECT * FROM VALGRUPEVANZAREIDX


SELECT * FROM NOM_CATEG WHERE GRUPA_VANZARE LIKE '%LOGICA%CAZANE%'

SELECT * FROM PROPRIETATI WHERE TIP='NOMENCL             '

SELECT distinct VALOARE_ATRIBUT_PRODUS FROM CON_CLIENTI
select distinct furnizor, GRUPA_VANZARE from NOM_CATEG

SELECT * FROM catproprietati
SELECT * FROM VALproprietati

select * 
into nomencl_codurimari
from nomencl n where len(n.cod)>20
and cod in  (select cod from stocuri)

select * from pozcon
where cod in (select cod from nomencl_codurimari)

select * 
into pozcon_coduri_mari
from pozcon where Subunitate='1' and (Contract='' or cod in (select cod from nomencl_codurimari))

select * 
into codvama_coduri_mari
from codvama c where cod in (select cod from nomencl_codurimari)

--DELETE nomencl
where len(cod)>20
and cod not in  (select cod from stocuri)

--DELETE pozcon
from pozcon
where Subunitate='1' and (Contract='' or cod in (select cod from nomencl_codurimari))

--DELETE codvama
from codvama c where cod in (select cod from nomencl_codurimari)


DROP TABLE ATPURI_NOM_CATEG
SELECT TOP 0 * 
INTO ATPURI_NOM_CATEG
FROM proprietati

----TRUNCATE TABLE ATPURI_NOM_CATEG
----INSERT ATPURI_NOM_CATEG
SELECT 
'NOMENCL' AS Tip--Tip	char	no	20	     
,LEFT(COD,20) AS Cod--Cod	char	no	20	     
,'ATP' AS Cod_proprietate--Cod_proprietate	char	no	20	     
,MAX(UPPER(LEFT(REPLACE(ATP,'ATP',''),200))) AS Valoare--Valoare	char	no	200	     
,'' AS Valoare_tupla--Valoare_tupla	char	no	200	 
-- SELECT DISTINCT ATP
--INTO ATPURI_NOM_CATEG_CODURI_MARI
FROM NOM_CATEG where ATP<>''  AND LEN(cod)<=20 
group by cod

----DELETE proprietati
--WHERE Cod_proprietate='ATP'
----INSERT proprietati
--SELECT * FROM ATPURI_NOM_CATEG where ISNUMERIC(Valoare)=1

DROP TABLE VALATPURI_NOM_CATEG
SELECT TOP 0 * 
INTO VALATPURI_NOM_CATEG
FROM VALproprietati

--INSERT VALATPURI_NOM_CATEG
SELECT DISTINCT
'ATP' --Cod_proprietate	char	no	20
,UPPER(LEFT(REPLACE(ATP,'ATP',''),200)) --Valoare	char	no	200
,UPPER(LEFT(REPLACE(ATP,'ATP',''),200))+' ZILE' --Descriere	char	no	80
,'' --Valoare_proprietate_parinte	char	no	200
FROM NOM_CATEG where ATP<>''

--DELETE VALproprietati
WHERE Cod_proprietate='ATP'
--INSERT VALproprietati
SELECT * FROM VALATPURI_NOM_CATEG


----INSERT nomencl
SELECT [codnou]
      ,[Tip]
      ,[Denumire]
      ,[UM]
      ,[UM_1]
      ,[Coeficient_conversie_1]
      ,[UM_2]
      ,[Coeficient_conversie_2]
      ,[Cont]
      ,[Grupa]
      ,[Valuta]
      ,[Pret_in_valuta]
      ,[Pret_stoc]
      ,[Pret_vanzare]
      ,[Pret_cu_amanuntul]
      ,[Cota_TVA]
      ,[Stoc_limita]
      ,[Stoc]
      ,[Greutate_specifica]
      ,[Furnizor]
      ,cod
      ,[Gestiune]
      ,[Categorie]
      ,[Tip_echipament]
  FROM [TET].[dbo].[nomencl_coduri_mari]
  
  select codnou
  from nomencl_coduri_mari
  group by codnou
  having COUNT(*)>1


select * from nomencl n
join nomencl_coduri_mari nc on nc.codnou=n.Cod

----DELETE nomencl
-- from nomencl n
--join nomencl_coduri_mari nc on nc.codnou=n.Cod

select * from nomencl n
where n.Cont like '%480%'

select top 0 *
into STOCLIM_LOCATORI
from stoclim

----INSERT STOCLIM_NOM_CATEG
SELECT --*,
'1'	--Subunitate	char	9
,'C'	--Tip_gestiune	char	1
,'101'	--Cod_gestiune	char	9
,LEFT(COD,20)	--Cod	char	20
,'2012-01-01'	--Data	datetime	8
,N.STOC_MIN	--Stoc_min	float	8
,N.STOC_MAX	--Stoc_max	float	8
,0	--Pret	float	8
,''	--Locatie	char	30
	-- SELECT MAX(LEN(COD))
FROM NOM_CATEG N
WHERE N.STOC_MAX+N.STOC_MIN<>''

----TRUNCATE TABLE STOCLIM
--INSERT stoclim
SELECT * FROM STOCLIM_NOM_CATEG

SELECT DENSE_RANK() OVER(ORDER BY ARTICOL) ,* FROM LOCATORI ORDER BY ARTICOL
DD
--select top 0 * 
--into PROD_MAG_NOMENCL
--from nomencl
-- -- TRUNCATE TABLE PROD_MAG_NOMENCL INSERT PROD_MAG_NOMENCL
SELECT --* ,
LEFT(P.COD,20)	--Cod	char	no	20
,'M'	--Tip	char	no	1
,MAX(LEFT(P.Denumirea_produsului,150))	--Denumire	char	no	150
,MAX(LEFT(P.UM,3))	--UM	char	no	3
,''	--UM_1	char	no	3
,0	--Coeficient_conversie_1	float	no	8
,''	--UM_2	char	no	20
,0	--Coeficient_conversie_2	float	no	8
,'3711'	--Cont	char	no	13
,''	--Grupa	char	no	13
,''	--Valuta	char	no	3
,0	--Pret_in_valuta	float	no	8
,0	--Pret_stoc	float	no	8
,0	--Pret_vanzare	float	no	8
,MAX(CONVERT(FLOAT,P.[Pret_cu_TVA ]))	--Pret_cu_amanuntul	float	no	8
,24	--Cota_TVA	real	no	4
,0	--Stoc_limita	float	no	8
,0	--Stoc	float	no	8
,''	--Greutate_specifica	float	no	8
,MAX(CASE P.BRAND WHEN 'EVERPRO' THEN 'RO15107294' WHEN 'ERATA' THEN 'RO5314527' ELSE '' END)	--Furnizor	char	no	13
,''	--Loc_de_munca	char	no	150
,''	--Gestiune	char	no	13
,4	--Categorie	smallint	no	2
,''	--Tip_echipament	char	no	21
	-- SELECT *
from PROD_MAG_Erata_si_Ever_Pro P
GROUP BY P.COD

----INSERT nomencl 
select * from PROD_MAG_NOMENCL p where p.cod not in (select n.cod from nomencl n)

select * from nomencl where cont='3711'
-- update nomencl 
set cont='371.1'
where cont='' and tip='M'

select * from nomencl n join prod_mag_nomencl p on n.Cod=p.Cod
where n.Grupa<>'40'

--update nomencl 
set Grupa='40'
from nomencl n join prod_mag_nomencl p on n.Cod=p.Cod
where n.Grupa<>'40'

DROP TABLE NOMENCL_ARTICOLE_SERIALE
SELECT TOP 0 * 
INTO NOMENCL_ARTICOLE_SERIALE
FROM proprietati

---- TRUNCATE TABLE NOMENCL_ARTICOLE_SERIALE INSERT NOMENCL_ARTICOLE_SERIALE
SELECT 
'NOMENCL' AS Tip--Tip	char	no	20	     
,LEFT(S.COD,20) AS Cod--Cod	char	no	20	     
,'ARESERII' AS Cod_proprietate--Cod_proprietate	char	no	20	     
,'1' AS Valoare--Valoare	char	no	200	     
,'' AS Valoare_tupla--Valoare_tupla	char	no	200	 
-- SELECT max(len(cod))
--INTO ATPURI_NOM_CATEG_CODURI_MARI
FROM ARTICOLE_SERIALE S
--where ATP<>''  AND LEN(cod)<=20 
group by s.cod

--DELETE proprietati
WHERE Cod_proprietate='ARESERII'
--INSERT proprietati
SELECT * FROM NOMENCL_ARTICOLE_SERIALE where ISNUMERIC(Valoare)=1

SELECT * FROM NOMENCL_ARTICOLE_SERIALE ns where ns.Cod not in 
(select n.cod from nomencl n)