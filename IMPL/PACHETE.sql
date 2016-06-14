SELECT * FROM PACHETE
select *
--into PACHETEIDX
FROM tehn

--TRUNCATE TABLE PACHETEIDX
--INSERT PACHETEIDX
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

--TRUNCATE TABLE Tehn
--INSERT Tehn
SELECT * FROM PACHETEIDX

SELECT Cod_tehn FROM PACHETEIDX
GROUP BY Cod_tehn
HAVING COUNT(*)>1

SELECT TOP 0 *INTO NOMENCL_PACHETEIDX
FROM NOMENCL

--TRUNCATE TABLE NOMENCL_PACHETEIDX
--INSERT NOMENCL_PACHETEIDX
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

--INSERT nomenclidx
SELECT * FROM NOMENCL_PACHETEIDX
WHERE Cod NOT IN (SELECT Cod FROM nomenclidx)

--TRUNCATE TABLE nomencl
--INSERT nomencl
SELECT *
from nomenclidx

select cod from NOMENCL_PACHETEIDX
group by cod having count(*)>1



SELECT GRUPA FROM grupe
GROUP BY Grupa
HAVING COUNT(*)>1

SELECT TOP 0 *INTO NOMENCL_PACHETEARTICOLEIDX
FROM NOMENCL

--TRUNCATE TABLE NOMENCL_PACHETEARTICOLEIDX
--INSERT NOMENCL_PACHETEARTICOLEIDX
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

--INSERT nomenclidx
SELECT * FROM NOMENCL_PACHETEARTICOLEIDX
WHERE Cod NOT IN (SELECT COD FROM NOMENCLIDX)

select  *
--into PACHETE_ARTICOLEIDX
from TEHNPOZ --Cod_tehn, Tip, Nr, Cod, Loc_munca

--TRUNCATE TABLE PACHETE_ARTICOLEIDX
--INSERT PACHETE_ARTICOLEIDX

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

--INSERT tehnpoz
SELECT * FROM PACHETE_ARTICOLEIDX

select  *
into PACHETE_REZULTATEIDX
from TEHNPOZ --Cod_tehn, Tip, Nr, Cod, Loc_munca
WHERE TIP='R'

--TRUNCATE TABLE PACHETE_REZULTATEIDX
--INSERT PACHETE_REZULTATEIDX

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


--INSERT tehnpoz
SELECT * FROM PACHETE_REZULTATEIDX

select * 
from tehnpoz tp join nomencl_coduri_mari n on n.cod=tp.cod

--UPDATE tehnpoz
set Cod=codnou
from tehnpoz tp join nomencl_coduri_mari n on n.cod=tp.cod

select * 
from tehnpoz tp join nomencl_coduri_mari n on n.cod=tp.Cod_tehn

select tp.* 
into tehnpoz_coduri_mari
from tehnpoz tp join nomencl_coduri_mari n on n.cod=tp.Cod_tehn

--UPDATE tehnpoz_coduri_mari
set Cod_tehn=codnou
from tehnpoz_coduri_mari tp join nomencl_coduri_mari n on n.cod=tp.Cod_tehn

select Cod_tehn, Tip, Nr, Cod, Loc_munca 
from tehnpoz_coduri_mari
group by Cod_tehn, Tip, Nr, Cod, Loc_munca 
having COUNT(*)>1

select * from tehnpoz tp where exists 
(select 1 from tehnpoz_coduri_mari tc where tc.Cod_tehn=tp.Cod_tehn and tc.Tip=tp.Tip and tc.Nr=tp.Nr and tc.Cod=tp.Cod
and tc.Loc_munca=tp.Loc_munca)
select * from tehnpoz_coduri_mari where Cod_tehn='PKTER202HP30SLOX1C_1          '
select * from tehnpoz where Cod_tehn like 'PKTER202HP30SLOX1C_1%' and LEN(cod_tehn)>20

--DELETE tehnpoz
from tehnpoz tp where exists 
(select 1 from tehnpoz_coduri_mari tc where tc.Cod_tehn=tp.Cod_tehn and tc.Tip=tp.Tip and tc.Nr=tp.Nr and tc.Cod=tp.Cod
and tc.Loc_munca=tp.Loc_munca)

--UPDATE tehnpoz
set Cod_tehn=codnou
from tehnpoz tp join nomencl_coduri_mari n on n.cod=tp.Cod_tehn

select tp.* 
--into tehnpoz_coduri_mari
from tehn tp join nomencl_coduri_mari n on n.codnou=tp.Cod_tehn


--DELETE tehn
where Cod_tehn='PKTER202HP30SLOX1C_1          '

--UPDATE tehn
set Cod_tehn=codnou
from tehn tp join nomencl_coduri_mari n on n.cod=tp.Cod_tehn 
--where Cod_tehn not in (select codnou from nomencl_coduri_mari)

SELECT  * 
--into TEHN_CONFIG_PACHETE
from Tehn

-- TRUNCATE TABLE TEHN_CONFIG_PACHETE INSERT TEHN_CONFIG_PACHETE 
select --*,
LEFT(p.Pachet,20)	--Cod_tehn	char	20
,left(p.Denumire,150)	--Denumire	char	150
,'P'	--Tip_tehn	char	1
,'IMP'	--Utilizator	char	10
,GETDATE()	--Data_operarii	datetime	8
,''	--Ora_operarii	char	6
,''	--Data1	datetime	8
,''	--Data2	datetime	8
,''	--Alfa1	char	20
,''	--Alfa2	char	20
,''	--Alfa3	char	20
,''	--Alfa4	char	20
,''	--Alfa5	char	20
,''	--Val1	float	8
,''	--Val2	float	8
,''	--Val3	float	8
,''	--Val4	float	8
,''	--Val5	float	8 
	--SELECT *
from CONFIG_PACHETE P
where p.Pachet=p.Cod

--INSERT tehn
select * 
from TEHN_CONFIG_PACHETE c where c.Cod_tehn not in 
(select t.cod_tehn from tehn t)

select *
-- delete t
from tehn t join TEHN_CONFIG_PACHETE c on c.Cod_tehn=t.Cod_tehn

SELECT  * 
--into TEHNPOZ_CONFIG_PACHETE
from TehnPoz

-- TRUNCATE TABLE TEHNPOZ_CONFIG_PACHETE INSERT TEHNPOZ_CONFIG_PACHETE 
select --*,
LEFT(p.Pachet,20)	--Cod_tehn	char	20
,'M'	--Tip	char	1
,LEFT(p.cod,20)	--Cod	char	20
,''	--Cod_operatie	char	20
,10*ROW_NUMBER() over( partition by p.pachet order by p.cod)	--Nr	float	8
,'M'	--Subtip	char	1
,0	--Supr	float	8
,0	--Coef_consum	float	8
,0	--Randament	float	8
,P.cantitate	--Specific	float	8
,''	--Cod_inlocuit	char	30
,''	--Loc_munca	char	20
,''	--Obs	char	200
,''	--Utilaj	char	20
,0	--Timp_preg	float	8
,0	--Timp_util	float	8
,''	--Categ_salar	char	20
,0	--Norma_timp	float	8
,0	--Tarif_unitar	float	8
,0	--Lungime	float	8
,0	--Latime	float	8
,0	--Inaltime	float	8
,''	--Comanda	char	20
,''	--Alfa1	char	20
,''	--Alfa2	char	20
,''	--Alfa3	char	20
,''	--Alfa4	char	20
,''	--Alfa5	char	20
,0	--Val1	float	8
,0	--Val2	float	8
,0	--Val3	float	8
,0	--Val4	float	8
,0	--Val5	float	8
	--SELECT *
from CONFIG_PACHETE P
where p.Pachet<>p.Cod

-- INSERT TEHNPOZ_CONFIG_PACHETE 
select --*,
LEFT(p.Pachet,20)	--Cod_tehn	char	20
,'R'	--Tip	char	1
,LEFT(p.cod,20)	--Cod	char	20
,''	--Cod_operatie	char	20
,10*ROW_NUMBER() over( partition by p.pachet order by p.cod)	--Nr	float	8
,'P'	--Subtip	char	1
,0	--Supr	float	8
,0	--Coef_consum	float	8
,0	--Randament	float	8
,P.cantitate	--Specific	float	8
,''	--Cod_inlocuit	char	30
,''	--Loc_munca	char	20
,''	--Obs	char	200
,''	--Utilaj	char	20
,0	--Timp_preg	float	8
,0	--Timp_util	float	8
,''	--Categ_salar	char	20
,0	--Norma_timp	float	8
,0	--Tarif_unitar	float	8
,0	--Lungime	float	8
,0	--Latime	float	8
,0	--Inaltime	float	8
,''	--Comanda	char	20
,''	--Alfa1	char	20
,''	--Alfa2	char	20
,''	--Alfa3	char	20
,''	--Alfa4	char	20
,''	--Alfa5	char	20
,0	--Val1	float	8
,0	--Val2	float	8
,0	--Val3	float	8
,0	--Val4	float	8
,0	--Val5	float	8
	--SELECT *
from CONFIG_PACHETE P
where p.Pachet=p.Cod

select *
-- delete t
from tehnpoz t join TEHN_CONFIG_PACHETE c on c.Cod_tehn=t.Cod_tehn

--insert tehnpoz
select * from TEHNPOZ_CONFIG_PACHETE c


select * from TEHNPOZ_CONFIG_PACHETE c
where c.cod not in (select n.cod from nomencl n)

select * from TEHN_CONFIG_PACHETE c
where c.cod_tehn not in (select n.cod from nomencl n)

SELECT *
--INTO NOMENCL_CONFIG_PACHETE
FROM NOMENCL

-- TRUNCATE TABLE NOMENCL_CONFIG_PACHETE INSERT NOMENCL_CONFIG_PACHETE
SELECT --*,
LEFT(p.Cod,20)	--Cod	char	20
,'P'	--Tip	char	1
,LEFT(p.Denumire,150)	--Denumire	char	150
,'BUC'	--UM	char	3
,''	--UM_1	char	3
,0	--Coeficient_conversie_1	float	8
,''	--UM_2	char	20
,0	--Coeficient_conversie_2	float	8
,'371.1'	--Cont	char	13
,''	--Grupa	char	13
,''	--Valuta	char	3
,0	--Pret_in_valuta	float	8
,0	--Pret_stoc	float	8
,0	--Pret_vanzare	float	8
,0	--Pret_cu_amanuntul	float	8
,24	--Cota_TVA	real	4
,0	--Stoc_limita	float	8
,0	--Stoc	float	8
,0	--Greutate_specifica	float	8
,''	--Furnizor	char	13
,''	--Loc_de_munca	char	150
,''	--Gestiune	char	13
,1	--Categorie	smallint	2
,''	--Tip_echipament	char	21
	-- select *
from CONFIG_PACHETE P
where p.Pachet=p.Cod

-- insert nomencl
select * from NOMENCL_CONFIG_PACHETE c where c.cod not in (select n.cod from nomencl n)