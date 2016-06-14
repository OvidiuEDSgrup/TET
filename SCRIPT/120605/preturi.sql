select * 
--INTO PRETURIDX
from PRETURI

TRUNCATE TABLE PRETURIDX
INSERT PRETURIDX
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

TRUNCATE TABLE PRETURIDX
INSERT PRETURIDX
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


--TRUNCATE TABLE PRETURIDX
INSERT PRETURIDX
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

TRUNCATE TABLE PRETURI
INSERT PRETURI
SELECT * FROM PRETURIDX

SELECT * FROM PRETURI P WHERE P.Cod_produs NOT IN
(SELECT COD FROM NOMENCL)

SELECT TOP 0 *
INTO NOMENCLPRETIDX
FROM NOMENCL

INSERT NOMENCLPRETIDX
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

INSERT NOMENCLPRETIDX
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

INSERT NOMENCL
SELECT * 
FROM NOMENCLPRETIDX
WHERE COD NOT IN 
(SELECT COD FROM NOMENCL)

UPDATE NOMENCL
SET Valuta=n.valuta,
Pret_in_valuta=n.Pret_in_valuta,
Pret_stoc=n.Pret_stoc,
Pret_vanzare=n.Pret_vanzare,
Categorie=n.Categorie
from nomencl join NOMENCLPRETIDX n on nomencl.Cod=N.cod