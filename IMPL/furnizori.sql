SELECT TOP 0 *
INTO FURNIZORIDX
FROM TERTI

--TRUNCATE TABLE FURNIZORIDX
--INSERT FURNIZORIDX
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

--TRUNCATE TABLE TERTIDX
--INSERT tertiDX
SELECT * FROM FURNIZORIDX

--INSERT  TERTI 
SELECT * FROM FURNIZORIDX
WHERE TERT NOT IN (SELECT TERT FROM terti)

SELECT TERT FROM TERTIDX GROUP BY TERT HAVING COUNT(*)>1

SELECT TOP 0 *
INTO FURNIZORI_PUTINIDX
FROM TERTI

--TRUNCATE TABLE FURNIZORI_PUTINIDX
--INSERT FURNIZORI_PUTINIDX
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

SELECT TOP 0 * 
--INTO FURNIZORI_SOLD_FACTIMPL
FROM FACTIMPL

--TRUNCATE TABLE FURNIZORI_SOLD_FACTIMPL
--INSERT FURNIZORI_SOLD_FACTIMPL
SELECT --*,
'1'	--Subunitate	char	9
,'1'	--Loc_de_munca	char	9
,0x54	--Tip	binary	1
--,'IMPL'+LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)	--Factura	char	25
,LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)+RIGHT(RTRIM(CS.[cont contabil]),7)
--+LTRIM(CONVERT(CHAR,ROW_NUMBER() OVER(PARTITION BY cs.cod_fiscal, cs.[cont contabil] ORDER BY CS.[sold 31dec] DESC)))
,ISNULL((SELECT MAX(t.tert) from terti t where t.Cod_fiscal like max(CS.cod_fiscal) or t.Denumire like max(cs.denumire)),
LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13))	--Tert	char	13
,'2011-12-31'	--Data	datetime	8
,'2011-12-31'	--Data_scadentei	datetime	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold 31dec],',','')))	--Valoare	float	8
,0	--TVA_11	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold 31dec],',',''))*(0))	--TVA_22	float	8
,''	--Valuta	char	3
,0	--Curs	float	8
,0	--Valoare_valuta	float	8
,0	--Achitat	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold 31dec],',','')))	--Sold	float	8
,LEFT(CS.[cont contabil],13)	--Cont_de_tert	char	13
,0	--Achitat_valuta	float	8
,0	--Sold_valuta	float	8
,''	--Comanda	char	40
,''	--Data_ultimei_achitari	datetime	8
	-- SELECT * 
FROM FURNIZORI_SOLD CS
WHERE CS.Cod_fiscal<>'' AND CONVERT(FLOAT,REPLACE(CS.[sold 31dec],',',''))>0.001
GROUP BY CS.Cod_fiscal,CS.[cont contabil]

select --top 0
* 
--into CLIENTI_SOLD_FACTIMPL
from test..factimpl

--INSERT factimpl
SELECT * FROM FURNIZORI_SOLD_FACTIMPL

select top 0 *
INTO FURNIZORI_SOLD_LIPSA
FROM terti

--TRUNCATE TABLE FURNIZORI_SOLD_LIPSA
--INSERT FURNIZORI_SOLD_LIPSA
SELECT --*,
'1'	--Subunitate	char	9
,LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)	--Tert	char	13
,LEFT(CS.denumire,80 )	--Denumire	char	80
,LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)	--Cod_fiscal	char	16
,LEFT(CS.localitate,35)	--Localitate	char	35
,''	--Judet	char	20
,LEFT(CS.ADDRESS_LINE1,60)	--Adresa	char	60
,''	--Telefon_fax	char	20
,''	--Banca	char	20
,''	--Cont_in_banca	char	35
,0	--Tert_extern	bit	1
,'202' 	--Grupa	char	3
,'401.2'	--Cont_ca_furnizor	char	13
,'411.1'		--Cont_ca_beneficiar	char	13
,0	--Sold_ca_furnizor	float	8
,0	--Sold_ca_beneficiar	float	8
,0--Sold_maxim_ca_beneficiar	float	no	8	53   
,0 --Disccount_acordat	real	no	4	24  
	-- SELECT *
FROM FURNIZORI_SOLD CS
WHERE CS.Cod_fiscal<>'' 


--INSERT TERTI
SELECT * FROM FURNIZORI_SOLD_LIPSA
where tert NOT IN (SELECT TERT FROM TERTI)

SELECT * FROM factimpl
extcon
pozcon

select * FROM factimpl where tert not in (select tert from terti)

SELECT * FROM factimpl WHERE Factura LIKE 'IMPLRO14%'
SELECT * FROM TERTI
WHERE TERT LIKE 'RO14432505%'
SELECT * FROM TERTI F WHERE F.Tert LIKE '%[^ ] [^ ]%' 
--UPDATE FURNIZORI_SOLD_LIPSA
SET Tert=UPPER(REPLACE(TERT,' ',''))

SELECT UPPER(REPLACE(TERT,' ','')) FROM TERTI T
--WHERE T.TERT LIKE '%[^ ] [^ ]%' 
GROUP BY UPPER(REPLACE(TERT,' ',''))
HAVING COUNT(*)>1


SELECT TOP 0 * 
INTO FURNIZORI_SOLD_SERVICII_FACTIMPL
FROM FACTIMPL

--TRUNCATE TABLE FURNIZORI_SOLD_SERVICII_FACTIMPL
--INSERT FURNIZORI_SOLD_SERVICII_FACTIMPL
SELECT --*,
'1'	--Subunitate	char	9
,'1'	--Loc_de_munca	char	9
,0x54	--Tip	binary	1
--,'IMPL'+RTRIM(LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13))+LEFT(CS.[cont contabil],8)	--Factura	char	25
,RTRIM(LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13))+RIGHT(RTRIM(CS.[cont contabil]),7)
--+LTRIM(CONVERT(CHAR,ROW_NUMBER() OVER(PARTITION BY cs.cod_fiscal, cs.[cont contabil] ORDER BY CS.[sold 31 dec 2011] DESC))) 	--Factura	char	25
,ISNULL((SELECT MAX(t.tert) from terti t where t.Cod_fiscal like max(CS.cod_fiscal) or t.Denumire like max(cs.[Den furnizori])),
LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13))	--Tert	char	13
,'2011-12-31'	--Data	datetime	8
,'2011-12-31'	--Data_scadentei	datetime	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold 31 dec 2011],',','')))	--Valoare	float	8
,0	--TVA_11	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold 31 dec 2011],',',''))*(0))	--TVA_22	float	8
,''	--Valuta	char	3
,0	--Curs	float	8
,0	--Valoare_valuta	float	8
,0	--Achitat	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold 31 dec 2011],',','')))	--Sold	float	8
,LEFT(CS.[cont contabil],13)	--Cont_de_tert	char	13
,0	--Achitat_valuta	float	8
,0	--Sold_valuta	float	8
,''	--Comanda	char	40
,''	--Data_ultimei_achitari	datetime	8
	-- SELECT * 
FROM FURNIZORI_SOLD_SERVICII CS
WHERE CS.Cod_fiscal<>'' AND CONVERT(FLOAT,REPLACE(CS.[sold 31 dec 2011],',',''))>0.001
GROUP BY CS.Cod_fiscal,CS.[cont contabil]

--UPDATE FURNIZORI_SOLD_SERVICII
set [cont contabil]='401.3'
where [cont contabil]='4013'

--INSERT factimpl
SELECT * FROM FURNIZORI_SOLD_SERVICII_FACTIMPL

SELECT FACTURA,TERT
FROM FURNIZORI_SOLD_SERVICII_FACTIMPL
GROUP BY FACTURA,TERT
HAVING COUNT(*)>1

select * from FURNIZORI_SOLD_SERVICII_FACTIMPL f
where f.Tert not in (select t.tert from terti t)

--INSERT FURNIZORI_SOLD_SERVICII_FACTIMPL
SELECT * FROM FACTIMPL

select top 0 *
INTO FURNIZORI_SOLD_SERVICII_LIPSA
FROM terti

--TRUNCATE TABLE FURNIZORI_SOLD_SERVICII_LIPSA
--INSERT FURNIZORI_SOLD_SERVICII_LIPSA
SELECT --*,
'1'	--Subunitate	char	9
,LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)	--Tert	char	13
,LEFT(CS.[Den furnizori],80 )	--Denumire	char	80
,LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)	--Cod_fiscal	char	16
,LEFT(CS.localitate,35)	--Localitate	char	35
,''	--Judet	char	20
,LEFT(CS.ADDRESS_LINE1,60)	--Adresa	char	60
,''	--Telefon_fax	char	20
,''	--Banca	char	20
,''	--Cont_in_banca	char	35
,0	--Tert_extern	bit	1
,'202' 	--Grupa	char	3
,LEFT(CS.[cont contabil],13)	--Cont_ca_furnizor	char	13
,'411.1'		--Cont_ca_beneficiar	char	13
,0	--Sold_ca_furnizor	float	8
,0	--Sold_ca_beneficiar	float	8
,0--Sold_maxim_ca_beneficiar	float	no	8	53   
,0 --Disccount_acordat	real	no	4	24  
	-- SELECT *
FROM FURNIZORI_SOLD_SERVICII CS
WHERE CS.Cod_fiscal<>'' 


--INSERT TERTI
SELECT * FROM FURNIZORI_SOLD_SERVICII_LIPSA 
where tert NOT IN (SELECT TERT FROM TERTI)


-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

SELECT TOP 0 * 
INTO FURNIZORI_EXT_MARFA_FACTIMPL
FROM FACTIMPL


select * from factimpl f where f.Tert not in (select ff.tert from FURNIZORI_EXT_MARFA_FACTIMPL ff)
and f.Cont_de_tert in ('401.1','401.5')


--TRUNCATE TABLE FURNIZORI_EXT_MARFA_FACTIMPL
--INSERT FURNIZORI_EXT_MARFA_FACTIMPL
SELECT --*,
'1'	--Subunitate	char	9
,'1'	--Loc_de_munca	char	9
,0x54	--Tip	binary	1
--,'IMPL'+RTRIM(LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13))+LEFT(CS.[cont contabil],8)	--Factura	char	25
,RTRIM(LEFT(REPLACE(LTRIM(RTRIM(CS.VAT_REGISTRATION_NUM)),' ',''),13))+RIGHT(RTRIM(CS.[cont contabil]),7)
--+LTRIM(CONVERT(CHAR,ROW_NUMBER() OVER(PARTITION BY cs.cod_fiscal, cs.[cont contabil] ORDER BY CS.[sold 31 dec 2011] DESC))) 	--Factura	char	25
,ISNULL((SELECT MAX(t.tert) from terti t where t.Cod_fiscal like max(REPLACE(LTRIM(RTRIM(CS.VAT_REGISTRATION_NUM)),' ','')) or t.Denumire like max(cs.denumire)),
LEFT(REPLACE(LTRIM(RTRIM(CS.VAT_REGISTRATION_NUM)),' ',''),13))	--Tert	char	13
,'2011-12-31'	--Data	datetime	8
,'2011-12-31'	--Data_scadentei	datetime	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[VAL RON],',','')))	--Valoare	float	8
,0	--TVA_11	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[VAL RON],',',''))*(0))	--TVA_22	float	8
,MAX(UPPER(LEFT(CS.moneda,3)))	--Valuta	char	3
,MAX(CONVERT(FLOAT,REPLACE(CS.CURS,',','')))	--Curs	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[VAL EURO],',','')))	--Valoare_valuta	float	8
,0	--Achitat	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[VAL RON],',','')))	--Sold	float	8
,LEFT(CS.[cont contabil],13)	--Cont_de_tert	char	13
,0	--Achitat_valuta	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[VAL EURO],',','')))	--Sold_valuta	float	8
,''	--Comanda	char	40
,''	--Data_ultimei_achitari	datetime	8
	-- SELECT * 
FROM FURNIZORI_EXT_MARFA CS
WHERE CS.VAT_REGISTRATION_NUM<>'' AND CONVERT(FLOAT,REPLACE(CS.[VAL RON],',',''))>0.001
GROUP BY CS.VAT_REGISTRATION_NUM,CS.[cont contabil]

--UPDATE FURNIZORI_SOLD_SERVICII
set [cont contabil]='401.3'
where [cont contabil]='4013'

select * from FURNIZORI_EXT_MARFA_FACTIMPL f
where f.Tert not in (select t.tert from terti t)

--INSERT factimpl
SELECT * FROM FURNIZORI_EXT_MARFA_FACTIMPL

select * from FURNIZORI_EXT_MARFA_FACTIMPL f where f.Tert in 
(select e.tert from efimpl e)

select * from FURNIZORI_EXT_MARFA_FACTIMPL f where f.Tert not in 
(select e.tert from terti e)

SELECT FACTURA,TERT
FROM FURNIZORI_SOLD_SERVICII_FACTIMPL
GROUP BY FACTURA,TERT
HAVING COUNT(*)>1

--INSERT FURNIZORI_SOLD_SERVICII_FACTIMPL
SELECT * FROM FACTIMPL

select top 0 *
INTO FURNIZORI_EXT_MARFA_LIPSA
FROM terti

--TRUNCATE TABLE FURNIZORI_EXT_MARFA_LIPSA
--INSERT FURNIZORI_EXT_MARFA_LIPSA
SELECT --*,
'1'	--Subunitate	char	9
,LEFT(REPLACE(LTRIM(RTRIM(CS.VAT_REGISTRATION_NUM)),' ',''),13)	--Tert	char	13
,LEFT(CS.denumire,80 )	--Denumire	char	80
,LEFT(REPLACE(LTRIM(RTRIM(CS.VAT_REGISTRATION_NUM)),' ',''),13)	--Cod_fiscal	char	16
,LEFT(CS.localitate,35)	--Localitate	char	35
,LEFT(CS.tara,20)	--Judet	char	20
,LEFT(CS.ADDRESS_LINE1,60)	--Adresa	char	60
,''	--Telefon_fax	char	20
,''	--Banca	char	20
,''	--Cont_in_banca	char	35
,0	--Tert_extern	bit	1
,'202' 	--Grupa	char	3
,LEFT(CS.[cont contabil],13)	--Cont_ca_furnizor	char	13
,'411.1'		--Cont_ca_beneficiar	char	13
,0	--Sold_ca_furnizor	float	8
,0	--Sold_ca_beneficiar	float	8
,0--Sold_maxim_ca_beneficiar	float	no	8	53   
,0 --Disccount_acordat	real	no	4	24  
	-- SELECT *
FROM FURNIZORI_EXT_MARFA CS
WHERE CS.VAT_REGISTRATION_NUM<>'' AND CONVERT(FLOAT,REPLACE(CS.[VAL RON],',',''))>0.001


--INSERT TERTI
SELECT * FROM FURNIZORI_EXT_MARFA_LIPSA
where tert not in (select tert from terti)

select * from FURNIZORI_REST_UNCLIENT
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

SELECT TOP 0 * 
INTO factimpl_servicii
FROM FACTIMPL

--TRUNCATE TABLE FURNIZORI_REST_UNCLIENT_FACTIMPL
--INSERT FURNIZORI_REST_UNCLIENT_FACTIMPL
SELECT --*,
'1'	--Subunitate	char	9
,'1'	--Loc_de_munca	char	9
,CASE LEFT(CS.[cont contabil],3) WHEN '401' THEN 0x54 WHEN '411' THEN 0x46 ELSE 0 END --Tip	binary	1
--,'IMPL'+RTRIM(LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13))+LEFT(CS.[cont contabil],8)	--Factura	char	25
,RTRIM(LEFT(REPLACE(LTRIM(RTRIM(CS.[Cod fiscal])),' ',''),13))+RIGHT(RTRIM(CS.[cont contabil]),7)
--+LTRIM(CONVERT(CHAR,ROW_NUMBER() OVER(PARTITION BY cs.cod_fiscal, cs.[cont contabil] ORDER BY CS.[sold 31 dec 2011] DESC))) 	--Factura	char	25
,ISNULL((SELECT MAX(t.tert) from terti t where t.Cod_fiscal like max(REPLACE(LTRIM(RTRIM(CS.[Cod fiscal])),' ','')) or t.Denumire like max(cs.[Den furnizori])),
LEFT(REPLACE(LTRIM(RTRIM(CS.[Cod fiscal])),' ',''),13))	--Tert	char	13
,'2011-12-31'	--Data	datetime	8
,'2011-12-31'	--Data_scadentei	datetime	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold 31 dec 2011],',','')))	--Valoare	float	8
,0	--TVA_11	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold 31 dec 2011],',',''))*(0))	--TVA_22	float	8
,''	--Valuta	char	3
,0	--Curs	float	8
,0	--Valoare_valuta	float	8
,0	--Achitat	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold 31 dec 2011],',','')))	--Sold	float	8
,LEFT(CS.[cont contabil],13)	--Cont_de_tert	char	13
,0	--Achitat_valuta	float	8
,0	--Sold_valuta	float	8
,''	--Comanda	char	40
,''	--Data_ultimei_achitari	datetime	8
	-- SELECT * 
FROM FURNIZORI_REST_UNCLIENT CS
WHERE CS.[Cod fiscal]<>'' AND CONVERT(FLOAT,REPLACE(CS.[sold 31 dec 2011],',',''))>0.001
GROUP BY CS.[Cod fiscal],CS.[cont contabil]

select * from FURNIZORI_REST_UNCLIENT_FACTIMPL f
where f.Tert not in (select t.tert from terti t)

--UPDATE FURNIZORI_REST_UNCLIENT
set [cont contabil]='401.3'
where [cont contabil]='4013'

--INSERT factimpl
SELECT * FROM FURNIZORI_REST_UNCLIENT_FACTIMPL
where tert not in (select tert from terti)

SELECT FACTURA,TERT
FROM FURNIZORI_SOLD_SERVICII_FACTIMPL
GROUP BY FACTURA,TERT
HAVING COUNT(*)>1

--INSERT FURNIZORI_SOLD_SERVICII_FACTIMPL
SELECT * FROM FACTIMPL

select top 0 *
INTO FURNIZORI_REST_UNCLIENT_LIPSA
FROM terti

--TRUNCATE TABLE FURNIZORI_REST_UNCLIENT_LIPSA
--INSERT FURNIZORI_REST_UNCLIENT_LIPSA
SELECT --*,
'1'	--Subunitate	char	9
,LEFT(REPLACE(LTRIM(RTRIM(CS.[Cod fiscal])),' ',''),13)	--Tert	char	13
,LEFT(CS.[Den furnizori],80 )	--Denumire	char	80
,LEFT(REPLACE(LTRIM(RTRIM(CS.[Cod fiscal])),' ',''),13)	--Cod_fiscal	char	16
,LEFT(CS.localitate,35)	--Localitate	char	35
,''	--Judet	char	20
,LEFT(CS.ADDRESS_LINE1,60)	--Adresa	char	60
,''	--Telefon_fax	char	20
,''	--Banca	char	20
,''	--Cont_in_banca	char	35
,0	--Tert_extern	bit	1
,'202' 	--Grupa	char	3
,LEFT(CS.[cont contabil],13)	--Cont_ca_furnizor	char	13
,'411.1'		--Cont_ca_beneficiar	char	13
,0	--Sold_ca_furnizor	float	8
,0	--Sold_ca_beneficiar	float	8
,0--Sold_maxim_ca_beneficiar	float	no	8	53   
,0 --Disccount_acordat	real	no	4	24  
	-- SELECT *
FROM FURNIZORI_REST_UNCLIENT CS
WHERE CS.[Cod fiscal]<>'' 


--INSERT TERTI
SELECT * FROM FURNIZORI_REST_UNCLIENT_LIPSA
where tert not in (select t.tert from terti t)

--INSERT factimpl_copie1
SELECT * FROM FURNIZORI_SOLD_FACTIMPL

--INSERT factimpl_copie1
SELECT * FROM FURNIZORI_SOLD_SERVICII_FACTIMPL

--INSERT factimpl_copie1
SELECT * FROM FURNIZORI_EXT_MARFA_FACTIMPL

--INSERT factimpl_copie1
SELECT * FROM FURNIZORI_REST_UNCLIENT_FACTIMPL

select * from factimpl_servicii f
where f.Cont_de_tert not like '401.3'

----DELETE factimpl_servicii from factimpl_servicii f
--where f.Cont_de_tert not like '401.3'

select * from factimpl_servicii f
where f.tert in (select e.tert from efimpl e)

select f.tert , COUNT(distinct f.cont_de_tert) from factimpl f
where f.Tert in (select e.tert from efimpl e)
group by f.tert
having COUNT(distinct f.cont_de_tert)>1


SELECT TOP 0 * 
INTO FURNIZORI_EXT_MARFA_FACTURI_FACTIMPL
FROM FACTIMPL


--TRUNCATE TABLE FURNIZORI_EXT_MARFA_FACTURI_FACTIMPL
--INSERT FURNIZORI_EXT_MARFA_FACTURI_FACTIMPL
SELECT --*,
'1'	--Subunitate	char	9
,'1'	--Loc_de_munca	char	9
,0x54	--Tip	binary	1
--,'IMPL'+RTRIM(LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13))+LEFT(CS.[cont contabil],8)	
--,ISNULL(t.tert,RTRIM(LEFT(REPLACE(LTRIM(RTRIM(f.VAT_REGISTRATION_NUM)),' ',''),13)))+RIGHT(RTRIM(f.[cont contabil]),7)
--+LTRIM(CONVERT(CHAR,ROW_NUMBER() OVER(PARTITION BY cs.cod_fiscal, cs.[cont contabil] ORDER BY CS.[sold 31 dec 2011] DESC))) 	--Factura	char	25
,LEFT(cs.INVOICE_NUM,20) --Factura	char	25
,ISNULL(t.tert,LEFT(REPLACE(LTRIM(RTRIM(f.VAT_REGISTRATION_NUM)),' ',''),13))	--Tert	char	13
,max(cs.INVOICE_DATE) --Data	datetime	8
,max(cs.[scadenta factura]) --Data_scadentei	datetime	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[valoare _FACTURA_RON],',','')))	--Valoare	float	8
,0	--TVA_11	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[valoare _FACTURA_RON],',',''))*(0))	--TVA_22	float	8
,MAX(UPPER(LEFT(CS.moneda,3)))	--Valuta	char	3
,MAX(CONVERT(FLOAT,REPLACE(CS.[curs valutar fact],',','')))	--Curs	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[valoare _FACTURA_EURO],',','')))	--Valoare_valuta	float	8
,0	--Achitat	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[valoare _FACTURA_RON],',','')))	--Sold	float	8
,max(LEFT(f.[cont contabil],13))	--Cont_de_tert	char	13
,0	--Achitat_valuta	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[valoare _FACTURA_EURO],',','')))	--Sold_valuta	float	8
,''	--Comanda	char	40
,''	--Data_ultimei_achitari	datetime	8
	-- SELECT convert(date,cs.[scadenta factura]) ,* 
FROM FURNIZORI_EXT_MARFA_FACTURI CS
LEFT JOIN FURNIZORI_EXT_MARFA f on f.denumire like cs.VENDOR_NAME
LEFT JOIN terti t on t.Cod_fiscal like REPLACE(LTRIM(RTRIM(f.VAT_REGISTRATION_NUM)),' ','') or t.Denumire like cs.VENDOR_NAME
WHERE COALESCE(t.tert,f.VAT_REGISTRATION_NUM,'')<>'' AND CONVERT(FLOAT,REPLACE(cs.[valoare _FACTURA_RON],',',''))>0.001
GROUP BY t.tert,f.VAT_REGISTRATION_NUM,cs.INVOICE_NUM --,f.[cont contabil]

--UPDATE FURNIZORI_SOLD_SERVICII
set [cont contabil]='401.3'
where [cont contabil]='4013'

select * from FURNIZORI_EXT_MARFA_FACTIMPL f
where f.Tert not in (select t.tert from terti t)

--INSERT factimpl
SELECT * FROM FURNIZORI_EXT_MARFA_FACTIMPL

select * from factimpl f where f.Tert in (select ff.tert from FURNIZORI_EXT_MARFA_FACTURI_FACTIMPL ff)
and f.Cont_de_tert in ('401.1','401.5')

select * from FURNIZORI_EXT_MARFA_FACTURI_FACTIMPL f
where f.Tert not in (select t.tert from terti t)

--DELETE factimpl 
from factimpl f where f.Tert in (select ff.tert from FURNIZORI_EXT_MARFA_FACTURI_FACTIMPL ff)
and f.Cont_de_tert in ('401.1','401.5')

--INSERT factimpl
select * from FURNIZORI_EXT_MARFA_FACTURI_FACTIMPL


select * from pozcon p join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Data=p.Data and c.Contract=p.Contract and c.Tert=p.Tert
join terti t on c.Tert=t.Tert
where p.Subunitate='1' and p.Tip='FA' and t.Cont_ca_furnizor='401.2' and p.valuta<>''

----UPDATE pozcon
--set Valuta=''
--from pozcon p join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Data=p.Data and c.Contract=p.Contract and c.Tert=p.Tert
--join terti t on c.Tert=t.Tert
--where p.Subunitate='1' and p.Tip='FA' and t.Cont_ca_furnizor='401.2' and p.valuta<>''

select * from con c join terti t on c.Tert=t.Tert
where c.Subunitate='1' and c.Tip='FA' and t.Cont_ca_furnizor='401.2' and c.valuta<>''


--UPDATE con
set Valuta=''
from con c join terti t on c.Tert=t.Tert
where c.Subunitate='1' and c.Tip='FA' and t.Cont_ca_furnizor='401.2' and c.valuta<>''