SELECT TOP 0 * 
--INTO CON_FURNIZORIDX
FROM con

INSERT CON_FURNIZORIDX
SELECT
'1'	--Subunitate	char	no	9
,LEFT(TIP,2)	--Tip	char	no	2
,LEFT(REPLACE(REPLACE(RTRIM(TERT),' ',''),'.',''),20)	--Contract	char	no	20
,RIGHT(REPLACE(REPLACE(RTRIM(TERT),' ',''),'.',''),13)	--Tert	char	no	13
,''	--Punct_livrare	char	no	13
,'2012-01-01'	--Data	datetime	no	8
,'1'	--Stare	char	no	1
,LEFT(Loc_de_munca,9)	--Loc_de_munca	char	no	9
,LEFT(Gestiune,9)	--Gestiune	char	no	9
,'2012-01-01'	--Termen	datetime	no	8
,CASE ISNUMERIC(REPLACE(REPLACE(scadenta,'zile',''),'avans','0')) WHEN 1 THEN CONVERT(smallint,REPLACE(REPLACE(scadenta,'zile',''),'avans',''))
	ELSE 0 END	--Scadenta	smallint	no	2
,0	--Discount	real	no	4
,LEFT(Valuta,3)	--Valuta	char	no	3
,0	--Curs	float	no	8
,LEFT(Mod_plata,1)	--Mod_plata	char	no	1
,''	--Mod_ambalare	char	no	1
,''	--Factura	char	no	20
,0	--Total_contractat	float	no	8
,0	--Total_TVA	float	no	8
,''	--Contract_coresp	char	no	20
,''	--Mod_penalizare	char	no	13
,0	--Procent_penalizare	real	no	4
,0	--Procent_avans	real	no	4
,0	--Avans	float	no	8
,0	--Nr_rate	smallint	no	2
,0	--Val_reziduala	float	no	8
,0	--Sold_initial	float	no	8
,''	--Cod_dobanda	char	no	20
,0	--Dobanda	real	no	4
,0	--Incasat	float	no	8
,''	--Responsabil	char	no	20
,''	--Responsabil_tert	char	no	20
,''	--Explicatii	char	no	50
,''	--Data_rezilierii	datetime	no	8
--,select *
FROM CON_FURNIZORI

SELECT TOP 0 *
INTO TERTICONIDX
FROM TERTI

INSERT TERTICONIDX
SELECT 
'1'	--Subunitate	char	no	9
,RIGHT(REPLACE(REPLACE(RTRIM(TERT),' ',''),'.',''),13)	--Tert	char	no	13
,LEFT(FURNIZOR,80)	--Denumire	char	no	80
,RIGHT(REPLACE(REPLACE(RTRIM(TERT),' ',''),'.',''),16)	--Cod_fiscal	char	no	16
,''	--Localitate	char	no	35
,''	--Judet	char	no	20
,''	--Adresa	char	no	60
,''	--Telefon_fax	char	no	20
,''	--Banca	char	no	20
,''	--Cont_in_banca	char	no	35
,0	--Tert_extern	bit	no	1
,''	--Grupa	char	no	3
,'4012'	--Cont_ca_furnizor	char	no	13
,'4111'	--Cont_ca_beneficiar	char	no	13
,0	--Sold_ca_furnizor	float	no	8
,0	--Sold_ca_beneficiar	float	no	8
,0	--Sold_maxim_ca_beneficiar	float	no	8
,0	--Disccount_acordat	real	no	4
--,*
FROM CON_FURNIZORI

INSERT TERTIDX
SELECT * FROM TERTICONIDX
WHERE TERT NOT IN (SELECT TERT FROM TERTIDX)

--TRUNCATE TABLE TERTI
INSERT TERTI
SELECT * FROM TERTIDX

/*
SELECT MAX(LEN(REPLACE(TERT,' ',''))) FROM CON_FURNIZORI
SELECT * FROM CON_FURNIZORI
WHERE LEN(REPLACE(TERT,' ',''))>13
*/
DROP TABLE POZCON_FURNIZORIDX
SELECT TOP 0 *
INTO POZCON_FURNIZORIDX
FROM POZCON

TRUNCATE TABLE POZCON_FURNIZORIDX
INSERT POZCON_FURNIZORIDX
SELECT 
'1'	--Subunitate	char	no	9
,'FA'	--Tip	char	no	2
,RIGHT(REPLACE(REPLACE(RTRIM(TERT),' ',''),'.',''),20)	--Contract	char	no	20
,RIGHT(REPLACE(REPLACE(RTRIM(TERT),' ',''),'.',''),13)	--Tert	char	no	13
,''	--Punct_livrare	char	no	13
,'2012-01-01'	--Data	datetime	no	8
,LEFT(Cod,30)	--Cod	char	no	30
,0	--Cantitate	float	no	8
,PRET_	--Pret	float	no	8
,0	--Pret_promotional	float	no	8
,0	--Discount	real	no	4
,''	--Termen	datetime	no	8
,''	--Factura	char	no	9
,0	--Cant_disponibila	float	no	8
,0	--Cant_aprobata	float	no	8
,0	--Cant_realizata	float	no	8
,LEFT(Valuta,3)	--Valuta	char	no	3
,24	--Cota_TVA	real	no	4
,0	--Suma_TVA	float	no	8
,''	--Mod_de_plata	char	no	8
,''	--UM	char	no	1
,0	--Zi_scadenta_din_luna	smallint	no	2
,''	--Explicatii	char	no	200
,Numar_pozitie	--Numar_pozitie	int	no	4
,'IMPL'	--Utilizator	char	no	10
,GETDATE()	--Data_operarii	datetime	no	8
,''	--Ora_operarii	char	no	6
--,SELECT *
FROM POZCON_FURNIZORI
--WHERE DISCOUNT<>''

SELECT * FROM POZCON_FURNIZORI
WHERE TERT=''

select * from pozcon

DELETE con
WHERE TIP='FA'
insert con
select * from CON_FURNIZORIDX

DELETE pozcon
WHERE TIP='FA'
insert pozcon
select * from POZCON_FURNIZORIDX
where not exists (select 1 from pozcon  p where p.Subunitate=POZCON_FURNIZORIDX.Subunitate
and p.Tip=POZCON_FURNIZORIDX.Tip and p.Contract=POZCON_FURNIZORIDX.Contract
and p.Tert=POZCON_FURNIZORIDX.Tert and p.cod=POZCON_FURNIZORIDX.cod)

select Subunitate, Tip, Contract, Tert, Cod, Data, Numar_pozitie
from POZCON_FURNIZORIDX
group by Subunitate, Tip, Contract, Tert, Cod, Data, Numar_pozitie
having COUNT(*)>1

SELECT Contract
FROM POZCON_FURNIZORIDX
GROUP BY Subunitate, Tip, Contract, Tert, Cod, Data, Numar_pozitie
HAVING COUNT(*)>1

SELECT TOP 0 *
INTO NOMENCLCONIDX
FROM NOMENCL

TRUNCATE TABLE NOMENCLCONIDX
INSERT NOMENCLCONIDX
SELECT
LEFT(Cod,30)	--Cod	char	no	30
,'M'	--Tip	char	no	1
,LEFT([denumire produs],150)	--Denumire	char	no	150
,LEFT(UM,3)	--UM	char	no	3
,'' --UM_1	char	no	3
,''	--Coeficient_conversie_1	float	no	8
,''	--UM_2	char	no	20
,0	--Coeficient_conversie_2	float	no	8
,'3711'	--Cont	char	no	13
,''	--Grupa	char	no	13
,LEFT(Valuta,3)	--Valuta	char	no	3
,PRET_	--Pret_in_valuta	float	no	8
,0	--Pret_stoc	float	no	8
,0	--Pret_vanzare	float	no	8
,0	--Pret_cu_amanuntul	float	no	8
,24	--Cota_TVA	real	no	4
,0	--Stoc_limita	float	no	8
,0	--Stoc	float	no	8
,0	--Greutate_specifica	float	no	8
,RIGHT(REPLACE(REPLACE(RTRIM(TERT),' ',''),'.',''),13)	--Furnizor	char	no	13
,''	--Loc_de_munca	char	no	150
,''	--Gestiune	char	no	13
,''	--Categorie	smallint	no	2
,''	--Tip_echipament	char	no	21
FROM POZCON_FURNIZORI

INSERT NOMENCLidx
SELECT *
FROM NOMENCLCONIDX
WHERE Cod NOT IN 
(SELECT Cod FROM nomenclidx)

TRUNCATE TABLE nomencl
insert nomencl
select * from NOMENCLidx

delete pozcon where tert=''