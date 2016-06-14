SELECT TOP 0 *
INTO SALARIATI_PERSONAL 
FROM PERSONAL

----INSERT SALARIATI_PERSONAL 
SELECT --*, 
LEFT(S.COD,6)	--Marca	char	6
,LEFT(S.NUME,50)	--Nume	char	50
,LEFT(ISNULL((SELECT MAX(f.Cod_functie) FROM functii f where f.Denumire like s.functie),s.functie),6)	--Cod_functie	char	6
,'1'	--Loc_de_munca	char	9
,0	--Loc_de_munca_din_pontaj	bit	1
,''	--Categoria_salarizare	char	4
,''	--Grupa_de_munca	char	1
,0	--Salar_de_incadrare	float	8
,0	--Salar_de_baza	float	8
,0	--Salar_orar	float	8
,''	--Tip_salarizare	char	1
,''	--Tip_impozitare	char	1
,0	--Pensie_suplimentara	smallint	2
,0	--Somaj_1	smallint	2
,0	--As_sanatate	smallint	2
,0	--Indemnizatia_de_conducere	float	8
,0	--Spor_vechime	real	4
,0	--Spor_de_noapte	real	4
,0	--Spor_sistematic_peste_program	real	4
,0	--Spor_de_functie_suplimentara	float	8
,0	--Spor_specific	float	8
,0	--Spor_conditii_1	float	8
,0	--Spor_conditii_2	float	8
,0	--Spor_conditii_3	float	8
,0	--Spor_conditii_4	float	8
,0	--Spor_conditii_5	float	8
,0	--Spor_conditii_6	float	8
,0	--Sindicalist	bit	1
,0	--Salar_lunar_de_baza	float	8
,0	--Zile_concediu_de_odihna_an	smallint	2
,0	--Zile_concediu_efectuat_an	smallint	2
,0	--Zile_absente_an	smallint	2
,''	--Vechime_totala	datetime	8
,''	--Data_angajarii_in_unitate	datetime	8
,''	--Banca	char	25
,''	--Cont_in_banca	char	25
,null	--Poza	image	16
,CASE LEFT(S.CNP,1) WHEN '1' THEN 1 WHEN 2 THEN 0 ELSE NULL END	--Sex	bit	1
,'19'+STUFF(STUFF(RIGHT(LEFT(S.CNP,7),6),3,0,'-'),6,0,'-')	--Data_nasterii	datetime	8
,LEFT(S.CNP,13)	--Cod_numeric_personal	char	13
,''	--Studii	char	10
,''	--Profesia	char	10
,''	--Adresa	char	30
,''	--Copii	char	30
,0	--Loc_ramas_vacant	bit	1
,''	--Localitate	char	30
,''	--Judet	char	15
,''	--Strada	char	25
,''	--Numar	char	5
,0	--Cod_postal	int	4
,''	--Bloc	char	10
,''	--Scara	char	2
,''	--Etaj	char	2
,''	--Apartament	char	5
,0	--Sector	smallint	2
,''	--Mod_angajare	char	1
,''	--Data_plec	datetime	8
,''	--Tip_colab	char	3
,''	--grad_invalid	char	1
,0	--coef_invalid	real	4
,0	--alte_surse	bit	1
	-- SELECT *
from SALARIATI S

SELECT STUFF('832332',3,0,'-')

--select *
--into personal_agv 
--from personal
--TRUNCATE table personal
--INSERT personal
select * from SALARIATI_PERSONAL 

select * from personal
select * from functii

--UPDATE personal
set Cod_functie='1'