--
EROARE

TRUNCATE TABLE NOMENCLidx
INSERT NOMENCLidx
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



INSERT NOMENCLidx
SELECT *
FROM NOMENCLCONIDX
WHERE Cod NOT IN 
(SELECT Cod FROM nomenclidx)

INSERT nomenclidx
SELECT * FROM NOMENCL_PACHETEARTICOLEIDX
WHERE Cod NOT IN (SELECT COD FROM NOMENCLIDX)

INSERT nomenclidx
SELECT * FROM NOMENCL_PACHETEIDX
WHERE Cod NOT IN (SELECT Cod FROM nomenclidx)

INSERT NOMENCLIDX
SELECT * 
FROM NOMENCLPRETIDX
WHERE COD NOT IN 
(SELECT COD FROM NOMENCLIDX)

truncate table nomencl
insert nomencl
select * from NOMENCLidx



UPDATE NOMENCL
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

TRUNCATE TABLE GRUPEVANZAREIDX
INSERT GRUPEVANZAREIDX
SELECT 
'NOMENCL' --Tip	char	no	20	     
,LEFT(COD,30) --Cod	char	no	20	     
,'GRUPAVANZARE' --Cod_proprietate	char	no	20	     
,UPPER(LEFT(GRUPA_VANZARE,200)) --Valoare	char	no	200	     
,'' --Valoare_tupla	char	no	200	 
-- SELECT DISTINCT FURNIZOR, GRUPA_VANZARE    
FROM NOM_CATEG

INSERT proprietati
SELECT * FROM GRUPEVANZAREIDX

DROP TABLE VALGRUPEVANZAREIDX
SELECT TOP 0 * 
INTO VALGRUPEVANZAREIDX
FROM VALproprietati

INSERT VALGRUPEVANZAREIDX
SELECT DISTINCT
'GRUPAVANZARE' --Cod_proprietate	char	no	20
,UPPER(LEFT(GRUPA_PRODUS,200)) --Valoare	char	no	200
,UPPER(LEFT(GRUPA_PRODUS,200)) --Descriere	char	no	80
,'' --Valoare_proprietate_parinte	char	no	200
FROM NOM_CATEG

DELETE VALproprietati
WHERE Cod_proprietate='GRUPAVANZARE'
INSERT VALproprietati
SELECT * FROM VALGRUPEVANZAREIDX


SELECT * FROM NOM_CATEG WHERE GRUPA_VANZARE LIKE '%LOGICA%CAZANE%'

SELECT * FROM PROPRIETATI WHERE TIP='NOMENCL             '

SELECT distinct VALOARE_ATRIBUT_PRODUS FROM CON_CLIENTI
select distinct furnizor, GRUPA_VANZARE from NOM_CATEG

SELECT * FROM catproprietati
SELECT * FROM VALproprietati
