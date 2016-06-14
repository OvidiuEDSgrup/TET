SELECT * FROM PACHETE
select *
--into PACHETEIDX
FROM tehn

TRUNCATE TABLE PACHETEIDX
INSERT PACHETEIDX
SELECT DISTINCT
LEFT(COD_PK,30)	--Cod_tehn	char	no	30
,LEFT(DENUMIRE_PK,80)	--Denumire	char	no	80
,'P'	--Tip_tehn	char	no	1
,'IMPL'	--Utilizator	char	no	10
,GETDATE()	--Data_operarii	datetime	no	8
,''	--Ora_operarii	char	no	6
,''	--Data1	datetime	no	8
,''	--Data2	datetime	no	8
,''	--Alfa1	char	no	20
,''	--Alfa2	char	no	20
,''	--Alfa3	char	no	20
,''	--Alfa4	char	no	20
,''	--Alfa5	char	no	20
,0	--Val1	float	no	8
,0	--Val2	float	no	8
,0	--Val3	float	no	8
,0	--Val4	float	no	8
,0	--Val5	float	no	8
--,*
FROM PACHETE

SELECT MAX(LEN(COD_PK)) FROM PACHETE

TRUNCATE TABLE Tehn
INSERT Tehn
SELECT * FROM PACHETEIDX

SELECT Cod_tehn FROM PACHETEIDX
GROUP BY Cod_tehn
HAVING COUNT(*)>1

SELECT TOP 0 *INTO NOMENCL_PACHETEIDX
FROM NOMENCL

TRUNCATE TABLE NOMENCL_PACHETEIDX
INSERT NOMENCL_PACHETEIDX
SELECT DISTINCT
LEFT(COD_PK,30)	--Cod	char	no	30
,'P'	--Tip	char	no	1
,LEFT(DENUMIRE_PK,150)	--Denumire	char	no	150
,'BUC'	--UM	char	no	3
,''	--UM_1	char	no	3
,0	--Coeficient_conversie_1	float	no	8
,''	--UM_2	char	no	20
,0	--Coeficient_conversie_2	float	no	8
,'3711'	--Cont	char	no	13
,''	--Grupa	char	no	13
,''	--Valuta	char	no	3
,''	--Pret_in_valuta	float	no	8
,0	--Pret_stoc	float	no	8
,0	--Pret_vanzare	float	no	8
,0	--Pret_cu_amanuntul	float	no	8
,24	--Cota_TVA	real	no	4
,0	--Stoc_limita	float	no	8
,0	--Stoc	float	no	8
,0	--Greutate_specifica	float	no	8
,''	--Furnizor	char	no	13
,''	--Loc_de_munca	char	no	150
,''	--Gestiune	char	no	13
,''	--Categorie	smallint	no	2
,''	--Tip_echipament	char	no	21
--,*
FROM PACHETE

INSERT nomenclidx
SELECT * FROM NOMENCL_PACHETEIDX
WHERE Cod NOT IN (SELECT Cod FROM nomenclidx)

TRUNCATE TABLE nomencl
insert nomencl
SELECT *
from nomenclidx

select cod from NOMENCL_PACHETEIDX
group by cod having count(*)>1



SELECT GRUPA FROM grupe
GROUP BY Grupa
HAVING COUNT(*)>1

SELECT TOP 0 *INTO NOMENCL_PACHETEARTICOLEIDX
FROM NOMENCL

TRUNCATE TABLE NOMENCL_PACHETEARTICOLEIDX
INSERT NOMENCL_PACHETEARTICOLEIDX
SELECT DISTINCT
LEFT(COD_ARTICOL_IN_PK,30)	--Cod	char	no	30
,'M'	--Tip	char	no	1
,LEFT(DEN_ARTICOL_PK,150)	--Denumire	char	no	150
,'BUC'	--UM	char	no	3
,''	--UM_1	char	no	3
,0	--Coeficient_conversie_1	float	no	8
,''	--UM_2	char	no	20
,0	--Coeficient_conversie_2	float	no	8
,'3711'	--Cont	char	no	13
,''	--Grupa	char	no	13
,''	--Valuta	char	no	3
,''	--Pret_in_valuta	float	no	8
,0	--Pret_stoc	float	no	8
,0	--Pret_vanzare	float	no	8
,0	--Pret_cu_amanuntul	float	no	8
,24	--Cota_TVA	real	no	4
,0	--Stoc_limita	float	no	8
,0	--Stoc	float	no	8
,0	--Greutate_specifica	float	no	8
,''	--Furnizor	char	no	13
,''	--Loc_de_munca	char	no	150
,''	--Gestiune	char	no	13
,''	--Categorie	smallint	no	2
,''	--Tip_echipament	char	no	21
--,*
FROM PACHETE

INSERT nomenclidx
SELECT * FROM NOMENCL_PACHETEARTICOLEIDX
WHERE Cod NOT IN (SELECT COD FROM NOMENCLIDX)

select  *
--into PACHETE_ARTICOLEIDX
from TEHNPOZ --Cod_tehn, Tip, Nr, Cod, Loc_munca

TRUNCATE TABLE PACHETE_ARTICOLEIDX
INSERT PACHETE_ARTICOLEIDX

SELECT 
LEFT(COD_PK,30)	--Cod_tehn	char	no	30
,'M'	--Tip	char	no	1
,LEFT(COD_ARTICOL_IN_PK,30)	--Cod	char	no	30
,''	--Cod_operatie	char	no	20
,ITEM_NUM	--Nr	float	no	8
,'M'	--Subtip	char	no	1
,0	--Supr	float	no	8
,0	--Coef_consum	float	no	8
,0	--Randament	float	no	8
,CANTITATEA	--Specific	float	no	8
,''	--Cod_inlocuit	char	no	30
,''	--Loc_munca	char	no	20
,''	--Obs	char	no	200
,''	--Utilaj	char	no	20
,0	--Timp_preg	float	no	8
,0	--Timp_util	float	no	8
,''	--Categ_salar	char	no	20
,0	--Norma_timp	float	no	8
,0	--Tarif_unitar	float	no	8
,0	--Lungime	float	no	8
,0	--Latime	float	no	8
,0	--Inaltime	float	no	8
,''	--Comanda	char	no	20
,''	--Alfa1	char	no	20
,''	--Alfa2	char	no	20
,''	--Alfa3	char	no	20
,''	--Alfa4	char	no	20
,''	--Alfa5	char	no	20
,0	--Val1	float	no	8
,0	--Val2	float	no	8
,0	--Val3	float	no	8
,0	--Val4	float	no	8
,0	--Val5	float	no	8
--,*
FROM PACHETE

INSERT tehnpoz
SELECT * FROM PACHETE_ARTICOLEIDX

select  *
into PACHETE_REZULTATEIDX
from TEHNPOZ --Cod_tehn, Tip, Nr, Cod, Loc_munca
WHERE TIP='R'

TRUNCATE TABLE PACHETE_REZULTATEIDX
INSERT PACHETE_REZULTATEIDX

SELECT DISTINCT
LEFT(COD_PK,30)	--Cod_tehn	char	no	30
,'R'	--Tip	char	no	1
,LEFT(COD_PK,30)	--Cod	char	no	30
,''	--Cod_operatie	char	no	20
,10	--Nr	float	no	8
,'P'	--Subtip	char	no	1
,0	--Supr	float	no	8
,0	--Coef_consum	float	no	8
,0	--Randament	float	no	8
,1	--Specific	float	no	8
,''	--Cod_inlocuit	char	no	30
,''	--Loc_munca	char	no	20
,''	--Obs	char	no	200
,''	--Utilaj	char	no	20
,0	--Timp_preg	float	no	8
,0	--Timp_util	float	no	8
,''	--Categ_salar	char	no	20
,0	--Norma_timp	float	no	8
,0	--Tarif_unitar	float	no	8
,0	--Lungime	float	no	8
,0	--Latime	float	no	8
,0	--Inaltime	float	no	8
,''	--Comanda	char	no	20
,''	--Alfa1	char	no	20
,''	--Alfa2	char	no	20
,''	--Alfa3	char	no	20
,''	--Alfa4	char	no	20
,''	--Alfa5	char	no	20
,0	--Val1	float	no	8
,0	--Val2	float	no	8
,0	--Val3	float	no	8
,0	--Val4	float	no	8
,0	--Val5	float	no	8
--,*
FROM PACHETE


INSERT tehnpoz
SELECT * FROM PACHETE_REZULTATEIDX