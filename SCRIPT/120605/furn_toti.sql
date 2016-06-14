SELECT VAT_REGISTRATION_NUM,VAT_REGISTRATION_NUM1,* FROM FURN_TOTI WHERE VAT_REGISTRATION_NUM<>VAT_REGISTRATION_NUM1
SELECT * FROM FURNIZORI 
SELECT COUNT(DISTINCT REPLACE(NUM_1099,'.','')), COUNT(DISTINCT REPLACE(ATTRIBUTE14,'.','')), COUNT(DISTINCT REPLACE(ATTRIBUTE15,'.','')), 
COUNT(DISTINCT REPLACE(VAT_REGISTRATION_NUM,'.','')), COUNT(DISTINCT REPLACE(VAT_REGISTRATION_NUM1,'.','') )
FROM FURN_TOTI 

select * from FURN_TOTI WHERE REPLACE(NUM_1099,'.','')='' 
AND REPLACE(ATTRIBUTE14,'.','')='' 
AND REPLACE(ATTRIBUTE15,'.','')='' 
AND REPLACE(VAT_REGISTRATION_NUM,'.','')='' 
AND REPLACE(VAT_REGISTRATION_NUM1,'.','')='' 

SELECT * FROM FURN_TOTI WHERE (REPLACE(ATTRIBUTE14,'.','')<>'' OR REPLACE(ATTRIBUTE15,'.','')<>'' )
SELECT * FROM FURN_TOTI WHERE ADDRESS_LINE2 LIKE '%lucru%'

terti
infotert
Punct de lucru BC - Str. Republicii, nr 188, Bacau, cod postal 600303DN1, KM 174-941, NR 2

PCT. LUCRU BD. I.C. BRATIANU, NR.214, CONSTANTA

select * from infotert
select MAX(len(address_line1)) from FURN_TOTI 
select * from FURN_TOTI where len(address_line1)>60

DROP TABLE FURN_TOTIDX

SELECT TOP 0 * 
INTO FURN_TOTIDX
FROM TERTI

TRUNCATE TABLE FURN_TOTIDX
INSERT FURN_TOTIDX
SELECT 
'1' --Subunitate	char	no	9	     
,ISNULL(NULLIF(RIGHT(RTRIM(REPLACE(NUM_1099,'.','')),13),''), RIGHT(RTRIM(REPLACE(VAT_REGISTRATION_NUM1,' ','')),13)) --Tert	char	no	13	     
,LEFT(VENDOR_NAME,80) --Denumire	char	no	80	     
,ISNULL(NULLIF(RIGHT(RTRIM(REPLACE(NUM_1099,'.','')),16),''), RIGHT(RTRIM(REPLACE(VAT_REGISTRATION_NUM1,' ','')),16)) --Cod_fiscal	char	no	16	     
,ISNULL(NULLIF((SELECT MAX(cod_oras) from localitati where oras= STATE),''),LEFT(STATE,35)) --Localitate	char	no	35	     
,CASE CHARINDEX('EXTERN',VENDOR_SITE_CODE) 
	WHEN 0 THEN ISNULL(NULLIF((SELECT MAX(cod_judet) from localitati where oras= STATE),''),LEFT(STATE,20)) ELSE LEFT(COUNTRY,20) END --Judet	char	no	20	     
,CASE WHEN LEN(RTRIM(ADDRESS_LINE1)+' '+LTRIM(RTRIM(ADDRESS_LINE2)))<=60 THEN RTRIM(ADDRESS_LINE1)+' '+LTRIM(RTRIM(ADDRESS_LINE2)) 
	ELSE RTRIM(ADDRESS_LINE1) END --Adresa	char	no	60	     
,'' --Telefon_fax	char	no	20	     
,'' --Banca	char	no	20	     
,'' --Cont_in_banca	char	no	35	     
,CASE CHARINDEX('EXTERN',VENDOR_SITE_CODE) WHEN 0 THEN 0 ELSE 1 END --Tert_extern	bit	no	1	     
,ISNULL((SELECT MAX(GRUPA) FROM GTERTI WHERE DENUMIRE LIKE REPLACE(REPLACE(VENDOR_SITE_CODE,'INTERN',''),'EXTERN',''))
		,REPLACE(REPLACE(VENDOR_SITE_CODE,'INTERN',''),'EXTERN','')) --Grupa	char	no	3	     
,CASE CHARINDEX('EXTERN',VENDOR_SITE_CODE) WHEN 0 THEN '4012' ELSE '4011' END --Cont_ca_furnizor	char	no	13	     
,CASE CHARINDEX('EXTERN',VENDOR_SITE_CODE) WHEN 0 THEN '4111' ELSE '4113' END --Cont_ca_beneficiar	char	no	13	     
,0 --Sold_ca_furnizor	float	no	8	53   
,0 --Sold_ca_beneficiar	float	no	8	53   
,0 --Sold_maxim_ca_beneficiar	float	no	8	53   
,0 --Disccount_acordat	real	no	4	24   
FROM FURN_TOTI
WHERE 
NOT(REPLACE(NUM_1099,'.','')='' 
AND REPLACE(ATTRIBUTE14,'.','')='' 
AND REPLACE(ATTRIBUTE15,'.','')='' 
AND REPLACE(VAT_REGISTRATION_NUM,'.','')='' 
AND REPLACE(VAT_REGISTRATION_NUM1,'.','')='' )

truncate table tertidx
insert TERTIDX
select * from FURN_TOTIDX

truncate table terti
insert terti
select * from tertidx

(select ISNULL(NULLIF(RIGHT(REPLACE(NUM_1099,'.',''),13),''), RIGHT(REPLACE(VAT_REGISTRATION_NUM1,' ',''),13))
from FURN_TOTI
group by ISNULL(NULLIF(RIGHT(REPLACE(NUM_1099,'.',''),13),''), RIGHT(REPLACE(VAT_REGISTRATION_NUM1,' ',''),13))
having COUNT(*)>1)


SELECT * FROM GTERTI

SELECT MAX(LEN( STATE))
FROM FURN_TOTI

SELECT VENDOR_SITE_CODE, COUNT(*)
FROM FURN_TOTI GROUP BY VENDOR_SITE_CODE ORDER BY 2 DESC

UPDATE FURN_TOTI 
SET VENDOR_SITE_CODE='MIJLOACE FIXE INTERN'
WHERE VENDOR_SITE_CODE='MIJLOACE FIXE'

SELECT * FROM FURN_TOTI 
WHERE VENDOR_SITE_CODE='MIJLOACE FIXE'

select CASE CHARINDEX('EXTERN',VENDOR_SITE_CODE) WHEN 0 THEN 0 ELSE 1 END ,*
from FURN_TOTI 

select * from tertidx where tert in
(select tert
from tertidx 
group by tert
having COUNT(*)>1)
order by tert

select * from FURN_TOTI 

SELECT TOP 0 * 
INTO DATETERTIDX
FROM INFOTERT

TRUNCATE TABLE DATETERTIDX
insert DATETERTIDX
select
'1'--Subunitate	char	no	9	     
,ISNULL(NULLIF(RIGHT(RTRIM(REPLACE(NUM_1099,'.','')),13),''), RIGHT(RTRIM(REPLACE(VAT_REGISTRATION_NUM1,' ','')),13)) --Tert	char	no	13	     
,'' --Identificator	char	no	5	     
,'' --Descriere	char	no	30	     
,'' --Loc_munca	char	no	9	     
,'' --Pers_contact	char	no	20	     
,'' --Nume_delegat	char	no	30	     
,'' --Buletin	char	no	12	     
,'' --Eliberat	char	no	30	     
,'' --Mijloc_tp	char	no	20	     
,'' --Adresa2	char	no	20	     
,'' --Telefon_fax2	char	no	20	     
,'' --e_mail	char	no	50	     
,'' --Banca2	char	no	20	     
,'' --Cont_in_banca2	char	no	35	     
,ISNULL(NULLIF(LEFT(LTRIM(REPLACE(VAT_REGISTRATION_NUM,'.','')),20),''), LEFT(LTRIM(REPLACE(VAT_REGISTRATION_NUM1,' ','')),20))  --Banca3	char	no	20	     
,'' --Cont_in_banca3	char	no	35	     
,0 --Indicator	bit	no	1	     
,'' --Grupa13	char	no	13	     
,0 --Sold_ben	float	no	8	53   
,0 --Discount	real	no	4	24   
,0 --Zile_inc	smallint	no	2	5    
,'' --Observatii	char	no	30	   
-- SELECT *
FROM FURN_TOTI
WHERE 
NOT(REPLACE(NUM_1099,'.','')='' 
AND REPLACE(ATTRIBUTE14,'.','')='' 
AND REPLACE(ATTRIBUTE15,'.','')='' 
AND REPLACE(VAT_REGISTRATION_NUM,'.','')='' 
AND REPLACE(VAT_REGISTRATION_NUM1,'.','')='' )
--AND NOT EXISTS (SELECT 1 FROM INFOTERTIDX WHERE INFOTERT.Tert=)

insert infotert
select * from DATETERTIDX 
where not exists (select 1 from infotert where infotert.Tert=DATETERTIDX.Tert and Identificator='')

update infotert
set Banca3=DATETERTIDX.Banca3
from infotert join DATETERTIDX on infotert.Tert=DATETERTIDX.Tert and infotert.Identificator=''


SELECT TOP 0 * 
INTO PCTELUCRUIDX
FROM INFOTERT

TRUNCATE TABLE PCTELUCRUIDX
insert PCTELUCRUIDX
select
'1'--Subunitate	char	no	9	     
,ISNULL(NULLIF(RIGHT(RTRIM(REPLACE(NUM_1099,'.','')),13),''), RIGHT(RTRIM(REPLACE(VAT_REGISTRATION_NUM1,' ','')),13)) --Tert	char	no	13	     
,'1' --Identificator	char	no	5	     
,'PUNCT DE LUCRU' --Descriere	char	no	30	     
,'' --Loc_munca	char	no	9	     
,ISNULL(NULLIF((SELECT MAX(cod_oras) from localitati where oras= STATE),''),LEFT(STATE,35)) --Pers_contact	char	no	20	     
,'' --Nume_delegat	char	no	30	     
,'' --Buletin	char	no	12	     
,'' --Eliberat	char	no	30	     
,'' --Mijloc_tp	char	no	20	     
,'' --Adresa2	char	no	20	     
,CASE CHARINDEX('EXTERN',VENDOR_SITE_CODE) 
	WHEN 0 THEN ISNULL(NULLIF((SELECT MAX(cod_judet) from localitati where oras= STATE),''),LEFT(STATE,20)) ELSE LEFT(COUNTRY,20) END --Telefon_fax2	char	no	20	     
,LEFT(CASE WHEN LEN(RTRIM(ADDRESS_LINE2)+' '+LTRIM(RTRIM(ADDRESS_LINE3)))<=50 THEN RTRIM(ADDRESS_LINE2)+' '+LTRIM(RTRIM(ADDRESS_LINE3)) 
	ELSE RTRIM(ADDRESS_LINE2) END,50) --e_mail	char	no	50	     
,'' --Banca2	char	no	20	     
,'' --Cont_in_banca2	char	no	35	     
,'' --Banca3	char	no	20	     
,'' --Cont_in_banca3	char	no	35	     
,0 --Indicator	bit	no	1	     
,'' --Grupa13	char	no	13	     
,0 --Sold_ben	float	no	8	53   
,0 --Discount	real	no	4	24   
,0 --Zile_inc	smallint	no	2	5    
,'' --Observatii	char	no	30	   
-- SELECT *
FROM FURN_TOTI
WHERE 
NOT(REPLACE(NUM_1099,'.','')='' 
AND REPLACE(ATTRIBUTE14,'.','')='' 
AND REPLACE(ATTRIBUTE15,'.','')='' 
AND REPLACE(VAT_REGISTRATION_NUM,'.','')='' 
AND REPLACE(VAT_REGISTRATION_NUM1,'.','')='' )

DELETE INFOTERT WHERE Identificator='1'
insert infotert
select * from PCTELUCRUIDX 
where not exists (select 1 from infotert where infotert.Tert=PCTELUCRUIDX.Tert and Identificator='1')


SELECT * FROM INFOTERT

