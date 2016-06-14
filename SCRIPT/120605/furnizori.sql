SELECT TOP 0 *
INTO FURNIZORIDX
FROM TERTI

TRUNCATE TABLE FURNIZORIDX
INSERT FURNIZORIDX
SELECT  
'1'--Subunitate	char	no	9	     
,LEFT(NUM_1099,13)--Tert	char	no	13	     
,LEFT(VENDOR_NAME,80)--Denumire	char	no	80	     
,LEFT(NUM_1099,16)--Cod_fiscal	char	no	16	     
,''--Localitate	char	no	35	     
,''--Judet	char	no	20	     
,''--Adresa	char	no	60	     
,''--Telefon_fax	char	no	20	     
,''--Banca	char	no	20	     
,''--Cont_in_banca	char	no	35	     
,0--Tert_extern	bit	no	1	     
,'201'--Grupa	char	no	3	     
,'4012'--Cont_ca_furnizor	char	no	13	     
,'4111'--Cont_ca_beneficiar	char	no	13	     
,0--Sold_ca_furnizor	float	no	8	53   
,0--Sold_ca_beneficiar	float	no	8	53   
,0--Sold_maxim_ca_beneficiar	float	no	8	53   
,0--Disccount_acordat	real	no	4	24   
--select *
FROM FURNIZORI
WHERE VENDOR_TYPE_LOOKUP_CODE='VENDOR'
AND REPLACE(NUM_1099,'.','')<>''

select MAX(len(NUM_1099)) from furnizori
SELECT 

TRUNCATE TABLE TERTIDX
INSERT tertiDX
SELECT * FROM FURNIZORIDX

INSERT  TERTI 
SELECT * FROM FURNIZORIDX
WHERE TERT NOT IN (SELECT TERT FROM terti)

SELECT TERT FROM TERTIDX GROUP BY TERT HAVING COUNT(*)>1

SELECT TOP 0 *
INTO FURNIZORI_PUTINIDX
FROM TERTI

TRUNCATE TABLE FURNIZORI_PUTINIDX
INSERT FURNIZORI_PUTINIDX
SELECT  
nrcrt--Subunitate	char	no	9	     
,LEFT(ISNULL(NULLIF(REPLACE(Cod_fiscal,'.',''),''),ISNULL(NULLIF(REPLACE(VAT_REGISTRATION_NUM,'.',''),''),nrcrt)),13)--Tert	char	no	13	     
,LEFT(VENDOR_NAME,80)--Denumire	char	no	80	     
,LEFT(ISNULL(NULLIF(REPLACE(Cod_fiscal,'.',''),''),ISNULL(NULLIF(REPLACE(VAT_REGISTRATION_NUM,'.',''),''),nrcrt)),16) --Cod_fiscal	char	no	16	     
,ISNULL((SELECT MAX(cod_oras) FROM LOCALITATI L WHERE L.oras LIKE LOCALITATE),LEFT(LOCALITATE,35)) --Localitate	char	no	35	     
,ISNULL((SELECT MAX(cod_judet) FROM LOCALITATI L WHERE L.oras LIKE LOCALITATE),'') --Judet	char	no	20	     
,LEFT(ADDRESS_LINE1,60) --Adresa	char	no	60	     
,''--Telefon_fax	char	no	20	     
,''--Banca	char	no	20	     
,LEFT(VAT_REGISTRATION_NUM,35) --Cont_in_banca	char	no	35	     
,0--Tert_extern	bit	no	1	     
,'201'--Grupa	char	no	3	     
,LEFT(cont_contabil,13) --Cont_ca_furnizor	char	no	13	     
,'411.1'--Cont_ca_beneficiar	char	no	13	     
,0--Sold_ca_furnizor	float	no	8	53   
,0--Sold_ca_beneficiar	float	no	8	53   
,0--Sold_maxim_ca_beneficiar	float	no	8	53   
,0--Disccount_acordat	real	no	4	24   
-- select *
FROM FURNIZORI_PUTINI

DROP TABLE FURNIZORI_PUTINIUNICI1
SELECT 
'1' AS SUBUNITATE	,
CASE nrdubulura WHEN 1 then 
RTRIM(F.TERT) WHEN 2 THEN
ISNULL((SELECT MAX(t.TERT) FROM terti t where t.denumire like f.denumire)
,rTRIM(f.Tert)+LTRIM(f.Subunitate)) ELSE rTRIM(f.Tert)+LTRIM(f.Subunitate) end 	TERT,
Denumire	,
Cod_fiscal	,
Localitate	,
Judet	,
Adresa	,
Telefon_fax	,
Banca	,
Cont_in_banca	,
Tert_extern	,
Grupa	,
Cont_ca_furnizor	,
Cont_ca_beneficiar	,
Sold_ca_furnizor	,
Sold_ca_beneficiar	,
Sold_maxim_ca_beneficiar	,
Disccount_acordat	
INTO FURNIZORI_PUTINIUNICI1
FROM FURNIZORI_PUTINIDX f
left join 
(SELECT SUBUNITATE,Tert
,ROW_NUMBER() 
OVER(PARTITION BY TERT
 ORDER BY DENUMIRE DESC) AS nrdubulura
 from FURNIZORI_PUTINIDX ) dubluri_numerotate ON f.SUBUNITATE=dubluri_numerotate.SUBUNITATE 
 and f.tert=dubluri_numerotate.Tert
left join
(select tert,COUNT(DISTINCT Denumire ) as den_diferite, COUNT(*) totaldubuluri
from FURNIZORI_PUTINIDX
GROUP BY TERT
HAVING COUNT(DISTINCT Denumire )>1) codfdublat_furndiferiti
ON f.tert=codfdublat_furndiferiti.Tert
WHERE nrdubulura=1 
	OR nrdubulura>1 AND nrdubulura<= ISNULL(den_diferite,0) 

SELECT * FROM FURNIZORI_PUTINIUNICI
select MAX(len(cod_fiscal)) from FURNIZORI_PUTINI

SELECT tert FROM FURNIZORI_PUTINIUNICI
GROUP BY TERT
HAVING COUNT(*)>1

SELECT * FROM FURNIZORI_PUTINIUNICI
SELECT * FROM FURNIZORI_PUTINIUNICI1

SELECT * FROM FURNIZORI_PUTINIUNICI
WHERE TERT NOT IN 
(SELECT TERT FROM FURNIZORI_PUTINIUNICI1)

