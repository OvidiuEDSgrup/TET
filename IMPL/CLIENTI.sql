SELECT * FROM CLIENTI WHERE CODFISCAL=''
SELECT * FROM CLIENTI WHERE ZONA2<>ZONA
JUDET_REPREZ<>Judet 
OR ZONA2<>ZONA
select * from clienti where codfiscal not like 'R%'
select MAX(len(Adresa)) from clienti
select * from clienti where len(codfiscal)=14

select distinct tipclient from clienti

SELECT MAX(LEN(GRUPA)) FROM CLIENTI

--INSERT GTERTI
SELECT
100+ROW_NUMBER() over(order by grupa) --Grupa	char	no	3	     
,LEFT(GRUPA,30) --Denumire	char	no	30	     
,0--Discount_acordat	real	no	4	24   
--id	int	no	4	10   
FROM (select distinct grupa from CLIENTI WHERE GRUPA<>'') as tmp


SELECT TOP 0 * 
INTO CLIENTIDX
FROM TERTI

--TRUNCATE TABLE CLIENTIDX
--INSERT CLIENTIDX
select
'1'--Subunitate	char	no	9	     
,CASE WHEN LEN(CODFISCAL)<=13 THEN LEFT(CODFISCAL,13) ELSE RIGHT(RTRIM(CODFISCAL),13) END --Tert	char	no	13	     
,LEFT(CLIENT,80)--Denumire	char	no	80	     
,LEFT(CODFISCAL,16)--Cod_fiscal	char	no	16	     
,ISNULL(NULLIF((SELECT MAX(cod_oras) from localitati where oras= LOCALITATEA),''),LEFT(LOCALITATEA,35))--Localitate	char	no	35	     
,CASE JUDET_REPREZ 
WHEN '' THEN LEFT(JUDET,20) 
ELSE LEFT(JUDET_REPREZ,20) END--Judet	char	no	20	     
,LEFT(ADRESA,60)--Adresa	char	no	60	     
,''--Telefon_fax	char	no	20	     
,''--Banca	char	no	20	     
,''--Cont_in_banca	char	no	35	     
,0--Tert_extern	bit	no	1	     
,LEFT(ISNULL((SELECT MAX(G.GRUPA) FROM gterti G WHERE G.Denumire=CLIENTI.GRUPA),CLIENTI.GRUPA),3) --Grupa	char	no	3	     
,'4012'--Cont_ca_furnizor	char	no	13	     
,'4111'--Cont_ca_beneficiar	char	no	13	     
,0--Sold_ca_furnizor	float	no	8	53   
,0--Sold_ca_beneficiar	float	no	8	53   
,0--Sold_maxim_ca_beneficiar	float	no	8	53   
,0--Disccount_acordat	real	no	4	24   
--SELECT * 
FROM CLIENTI 
WHERE CODFISCAL<>''


select * from terti
where tert='RO7745470'

select * from infotert
where tert='RO7745470'

select REPLACE(LOC_MUNCA,',',''), REPLACE(REPREZENTATNT,',',''),* from clienti

----TRUNCATE TABLE TERTIDX
--INSERT TERTIDX
SELECT * FROM CLIENTIDX c
where c.Tert not in (select tert from tertidx)

SELECT TERT FROM TERTIDX GROUP BY TERT HAVING COUNT(*)>1

SELECT * FROM TERTI

--TRUNCATE TABLE TERTI
--INSERT TERTI
SELECT * FROM TERTIDX

select tert
from tertidx
group by tert having count(*)>1

SELECT * FROM CLIENTIDX
WHERE TERT IN (SELECT TERT FROM FURNIZORIDX)


SELECT TOP 0 * 
INTO PERSONALIDX
FROM PERSONAL

--TRUNCATE table PERSONAL
--INSERT PERSONAL
SELECT
RIGHT(COD,5),--Marca	char	no	6	     
LEFT(DENUMIRE,50),--Nume	char	no	50	     
'',--Cod_functie	char	no	6	     
lm.Cod_parinte,--Loc_de_munca	char	no	9	     
0,--Loc_de_munca_din_pontaj	bit	no	1	     
'',--Categoria_salarizare	char	no	4	     
'',--Grupa_de_munca	char	no	1	     
0,--Salar_de_incadrare	float	no	8	53   
0,--Salar_de_baza	float	no	8	53   
0,--Salar_orar	float	no	8	53   
'',--Tip_salarizare	char	no	1	     
'',--Tip_impozitare	char	no	1			
0,--Pensie_suplimentara	smallint	no	2	5    
0,--Somaj_1	smallint	no	2	5    
0,--As_sanatate	smallint	no	2	5    
0,--Indemnizatia_de_conducere	float	no	8	53   
0,--Spor_vechime	real	no	4	24   
0,--Spor_de_noapte	real	no	4	24   
0,--Spor_sistematic_peste_program	real	no	4	24   
0,--Spor_de_functie_suplimentara	float	no	8	53   
0,--Spor_specific	float	no	8	53   
0,--Spor_conditii_1	float	no	8	53   
0,--Spor_conditii_2	float	no	8	53   
0,--Spor_conditii_3	float	no	8	53   
0,--Spor_conditii_4	float	no	8	53   
0,--Spor_conditii_5	float	no	8	53   
0,--Spor_conditii_6	float	no	8	53   
0,--Sindicalist	bit	no	1	     
0,--Salar_lunar_de_baza	float	no	8	53   
0,--Zile_concediu_de_odihna_an	smallint	no	2	5    
0,--Zile_concediu_efectuat_an	smallint	no	2	5    
0,--Zile_absente_an	smallint	no	2	5    
'',--Vechime_totala	datetime	no	8	     
'',--Data_angajarii_in_unitate	datetime	no	8	     
'',--Banca	char	no	25	     
'',--Cont_in_banca	char	no	25	     
null,--Poza	image	no	16	     
0,--Sex	bit	no	1	     
'',--Data_nasterii	datetime	no	8	     
'',--Cod_numeric_personal	char	no	13	     
'',--Studii	char	no	10	     
'',--Profesia	char	no	10	     
'',--Adresa	char	no	30	     
'',--Copii	char	no	30	     
0,--Loc_ramas_vacant	bit	no	1	     
'',--Localitate	char	no	30	     
'',--Judet	char	no	15	     
'',--Strada	char	no	25	     
'',--Numar	char	no	5	     
0,--Cod_postal	int	no	4	10   
'',--Bloc	char	no	10	     
'',--Scara	char	no	2	     
'',--Etaj	char	no	2	     
'',--Apartament	char	no	5	     
0,--Sector	smallint	no	2	5    
'',--Mod_angajare	char	no	1	     
'',--Data_plec	datetime	no	8	     
'',--Tip_colab	char	no	3	     
'',--grad_invalid	char	no	1	     
0,--coef_invalid	real	no	4	24   
0--alte_surse	bit	no	1	     
--SELECT *
FROM LM WHERE Nivel =4 --AND Cod_parinte='1VNZAG' 
and cod LIKE '1VNZ_____'

select * from personal 

(SELECT DISTINCT LOC_MUNCA FROM CLIENTI WHERE LOC_MUNCA<>''
UNION
SELECT DISTINCT REPREZENTATNT FROM CLIENTI WHERE REPREZENTATNT<>''
UNION
SELECT AGV FROM AGENTI_ASM
UNION
SELECT ASM FROM AGENTI_ASM
ORDER BY 1

--TRUNCATE table personal
--INSERT personal 
select * from PERSONALIDX 

SELECT * FROM proprietati WHERE Tip='TERT'

SELECT TOP 0 * 
INTO TIPCLIENTIDX
FROM proprietati

--TRUNCATE TABLE TIPCLIENTIDX
--INSERT TIPCLIENTIDX
SELECT
'TERT' --Tip	char	no	20	     
,CASE WHEN LEN(CODFISCAL)<=13 THEN LEFT(CODFISCAL,13) ELSE RIGHT(RTRIM(CODFISCAL),13) END --Cod	char	no	20	     
,'TIPCLIENT' --Cod_proprietate	char	no	20	     
,TIPCLIENT --Valoare	char	no	200	     
,'' --Valoare_tupla	char	no	200	     
FROM CLIENTI
WHERE CODFISCAL<>''

--DELETE proprietati
WHERE TIP='TERT' AND Cod_proprietate='TIPCLIENT'

--INSERT proprietati
SELECT * FROM TIPCLIENTIDX

SELECT Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla
FROM TIPCLIENTIDX
GROUP BY Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla
HAVING COUNT(*)>1

select * from clienti

SELECT TOP 0 * 
INTO AGENTIDX
FROM INFOTERT

--TRUNCATE TABLE AGENTIDX
--INSERT AGENTIDX
select
'1'--Subunitate	char	no	9	     
,CASE WHEN LEN(CODFISCAL)<=13 THEN LEFT(CODFISCAL,13) ELSE RIGHT(RTRIM(CODFISCAL),13) END --Tert	char	no	13	     
,'' --Identificator	char	no	5	     
,LEFT(ISNULL((SELECT MAX(marca) FROM personal WHERE nume=REPLACE(REPREZENTATNT,',','')),REPLACE(REPREZENTATNT,',','')),30) --Descriere	char	no	30	     
,LEFT(ISNULL((SELECT MAX(cod) FROM lm WHERE denumire=REPLACE(LOC_MUNCA,',','')),REPLACE(LOC_MUNCA,',','')),9) --Loc_munca	char	no	9	     
,'' --Pers_contact	char	no	20	     
,'' --Nume_delegat	char	no	30	     
,'' --Buletin	char	no	12	     
,'' --Eliberat	char	no	30	     
,'' --Mijloc_tp	char	no	20	     
,'' --Adresa2	char	no	20	     
,'' --Telefon_fax2	char	no	20	     
,'' --e_mail	char	no	50	     
,'' --Banca2	char	no	20	     
,LEFT(LTRIM(WWW),35) --Cont_in_banca2	char	no	35	     
,LEFT(LTRIM(REGISTRU_COMERTULUI),20) --Banca3	char	no	20	     
,LEFT(LTRIM(EMAIL_ADDRESS),35) --Cont_in_banca3	char	no	35	     
,0 --Indicator	bit	no	1	     
,'' --Grupa13	char	no	13	     
,0 --Sold_ben	float	no	8	53   
,0 --Discount	real	no	4	24   
,0 --Zile_inc	smallint	no	2	5    
,'' --Observatii	char	no	30	   
-- SELECT *
FROM CLIENTI 
WHERE CODFISCAL<>''

SELECT TOP 0 *
INTO INFOTERTIDX
FROM INFOTERT

select * from infotert where tert='1500801270612'

--TRUNCATE TABLE INFOTERTIDX
--INSERT INFOTERTIDX
SELECT * FROM AGENTIDX

--TRUNCATE TABLE INFOTERT
--INSERT INFOTERT
SELECT * FROM AGENTIDX 

select * from AGV_ASM_ZONE B INNER JOIN AGV_ASM_ZONE S ON 
B.JGZZ_FISCAL_CODE=S.JGZZ_FISCAL_CODE
WHERE B.SITE='BILL_TO' AND S.SITE='SHIP_TO'


SELECT TOP 0 * 
INTO GRUPECLIENTIDX
FROM proprietati

--TRUNCATE TABLE GRUPECLIENTIDX
--INSERT GRUPECLIENTIDX
SELECT
'TERT' --Tip	char	no	20	     
,CASE WHEN LEN(CODFISCAL)<=13 THEN LEFT(CODFISCAL,13) ELSE RIGHT(RTRIM(CODFISCAL),13) END --Cod	char	no	20	     
,'GRUPACLIENT' --Cod_proprietate	char	no	20	     
,GRUPA --Valoare	char	no	200	     
,'' --Valoare_tupla	char	no	200	     
FROM CLIENTI
WHERE CODFISCAL<>''

--INSERT proprietati
select * from GRUPECLIENTIDX

----------------

SELECT * FROM CLIENTI_PUTINI
GTERTI
SELECT DISTINCT CASE WHEN SIC_CODE=SIC_CODE_TYPE THEN REPLACE(SIC_CODE,'0','') 
ELSE LEFT(RTRIM(REPLACE(SIC_CODE,'0',''))+' '+LTRIM(REPLACE(SIC_CODE_TYPE,'0','')),30) END FROM CLIENTI_PUTINI

SELECT TOP 0 * 
INTO CLIENTI_PUTINIDX
FROM TERTI

--TRUNCATE TABLE CLIENTI_PUTINIDX
--INSERT CLIENTI_PUTINIDX
select
'1'--Subunitate	char	no	9	     
,LEFT(ISNULL(NULLIF(REPLACE(Cod_fiscal,'.',''),''),ISNULL(NULLIF(REPLACE(TAX_REFERENCE,'.',''),''),Subunitate)),13) --Tert	char	no	13	     
,LEFT(CLIENT,80)--Denumire	char	no	80	     
,LEFT(ISNULL(NULLIF(REPLACE(Cod_fiscal,'.',''),''),ISNULL(NULLIF(REPLACE(TAX_REFERENCE,'.',''),''),Subunitate)),16)--Cod_fiscal	char	no	16	     
,''--Localitate	char	no	35	     
,''--Judet	char	no	20	     
,''--Adresa	char	no	60	     
,''--Telefon_fax	char	no	20	     
,''--Banca	char	no	20	     
,LEFT(TAX_REFERENCE,35) --Cont_in_banca	char	no	35	     
,0--Tert_extern	bit	no	1	     
,LEFT(ISNULL((SELECT MAX(G.GRUPA) FROM gterti G WHERE G.Denumire
	=CASE WHEN SIC_CODE=SIC_CODE_TYPE THEN REPLACE(SIC_CODE,'0','') 
	ELSE LEFT(RTRIM(REPLACE(SIC_CODE,'0',''))+' '+LTRIM(REPLACE(SIC_CODE_TYPE,'0','')),30) END)
	,CASE WHEN SIC_CODE=SIC_CODE_TYPE THEN REPLACE(SIC_CODE,'0','') 
	ELSE LEFT(RTRIM(REPLACE(SIC_CODE,'0',''))+' '+LTRIM(REPLACE(SIC_CODE_TYPE,'0','')),30) END),3) --Grupa	char	no	3	     
,'401.3'--Cont_ca_furnizor	char	no	13	     
,'411.1'--Cont_ca_beneficiar	char	no	13	     
,0--Sold_ca_furnizor	float	no	8	53   
,0--Sold_ca_beneficiar	float	no	8	53   
,CONVERT(INT,[limita credit])--Sold_maxim_ca_beneficiar	float	no	8	53   
,CONVERT(INT,REPLACE(REPLACE(termen_plata,'ZILE',''),'IMEDIAT','0')) --Disccount_acordat	real	no	4	24   
--SELECT TOP 4 * 
FROM CLIENTI_PUTINI
WHERE cod_fiscal<>''

SELECT TERT
FROM TERTI_PUTINIDX
GROUP BY TERT
HAVING COUNT(*)>1

select * from TERTI_PUTINIDX

drop table TERTI_PUTINIDX
select * 
INTO TERTI_PUTINIDX
from CLIENTI_PUTINIDX
union all
select * from FURNIZORI_PUTINIUNICI1
where tert not in 
(select tert from CLIENTI_PUTINIDX)

----INSERT terti2
select * from TERTI_PUTINIDX

--TRUNCATE table terti2
--INSERT terti2
select * from terti t
where t.tert not in 
(select tert from con c where tip in ('BF','FA')
union all
select tert from TERTI_PUTINIDX
union all
select furnizor from nomencl)

----DELETE t from terti t
where t.tert not in 
(select tert from con c where tip in ('BF','FA')
union all
select tert from TERTI_PUTINIDX
union all
select furnizor from nomencl)


----INSERT terti_vechi
select * from terti

select TP.TERT,
CASE t.Denumire	WHEN ISNULL(NULLIF(tp.Denumire,''),t.Denumire) THEN '' ELSE tp.Denumire END Denumire,
CASE t.Cod_fiscal	WHEN ISNULL(NULLIF(tp.Cod_fiscal,''),t.Cod_fiscal) THEN '' ELSE tp.Cod_fiscal END Cod_fiscal ,
CASE t.Localitate	WHEN ISNULL(NULLIF(tp.Localitate,''),t.Localitate) THEN '' ELSE tp.Localitate END Localitate ,
CASE t.Judet	WHEN ISNULL(NULLIF(tp.Judet,''),t.Judet) THEN '' ELSE tp.Judet END Judet ,
CASE t.Adresa	WHEN ISNULL(NULLIF(tp.Adresa,''),t.Adresa) THEN '' ELSE tp.Adresa END Adresa ,
CASE t.Telefon_fax	WHEN ISNULL(NULLIF(tp.Telefon_fax,''),t.Telefon_fax) THEN '' ELSE tp.Telefon_fax END Telefon_fax ,
CASE t.Banca	WHEN ISNULL(NULLIF(tp.Banca,''),t.Banca) THEN '' ELSE tp.Banca END Banca ,
CASE t.Cont_in_banca	WHEN ISNULL(NULLIF(tp.Cont_in_banca,''),t.Cont_in_banca) THEN '' ELSE tp.Cont_in_banca END Cont_in_banca ,
CASE t.Tert_extern	WHEN ISNULL(NULLIF(tp.Tert_extern,0),t.Tert_extern) THEN '' ELSE tp.Tert_extern END Tert_extern ,
CASE t.Grupa	WHEN ISNULL(NULLIF(tp.Grupa,''),t.Grupa) THEN '' ELSE tp.Grupa END Grupa ,
CASE t.Cont_ca_furnizor	WHEN ISNULL(NULLIF(tp.Cont_ca_furnizor,''),t.Cont_ca_furnizor) THEN '' ELSE tp.Cont_ca_furnizor END Cont_ca_furnizor ,
CASE t.Cont_ca_beneficiar	WHEN ISNULL(NULLIF(tp.Cont_ca_beneficiar,''),t.Cont_ca_beneficiar) THEN '' ELSE tp.Cont_ca_beneficiar END Cont_ca_beneficiar ,
CASE t.Sold_ca_furnizor	WHEN ISNULL(NULLIF(tp.Sold_ca_furnizor,0),t.Sold_ca_furnizor) THEN '' ELSE tp.Sold_ca_furnizor END Sold_ca_furnizor ,
CASE t.Sold_ca_beneficiar	WHEN ISNULL(NULLIF(tp.Sold_ca_beneficiar,0),tp.Sold_ca_beneficiar) THEN '' ELSE tp.Sold_ca_beneficiar END Sold_ca_beneficiar ,
CASE t.Sold_maxim_ca_beneficiar	WHEN ISNULL(NULLIF(tp.Sold_maxim_ca_beneficiar,0),tp.Sold_maxim_ca_beneficiar) THEN '' ELSE tp.Sold_maxim_ca_beneficiar END Sold_maxim_ca_beneficiar ,
CASE t.Disccount_acordat	WHEN ISNULL(NULLIF(tp.Disccount_acordat,0),tp.Disccount_acordat) THEN '' ELSE tp.Disccount_acordat END Disccount_acordat 
,T.*
from terti t INNER JOIN CLIENTI_SOLD_LIPSA tp ON t.Tert=tp.Tert
WHERE 
t.Denumire	<>tp.Denumire OR
t.Cod_fiscal	<>tp.Cod_fiscal OR
t.Localitate	<>tp.Localitate OR
t.Judet	<>tp.Judet OR
t.Adresa	<>tp.Adresa OR
t.Telefon_fax	<>tp.Telefon_fax OR
t.Banca	<>tp.Banca OR
t.Cont_in_banca	<>tp.Cont_in_banca OR
t.Tert_extern	<>tp.Tert_extern OR
t.Grupa	<>tp.Grupa OR
t.Cont_ca_furnizor	<>tp.Cont_ca_furnizor OR
t.Cont_ca_beneficiar	<>tp.Cont_ca_beneficiar OR
t.Sold_ca_furnizor	<>tp.Sold_ca_furnizor OR
t.Sold_ca_beneficiar	<>tp.Sold_ca_beneficiar OR
t.Sold_maxim_ca_beneficiar	<>tp.Sold_maxim_ca_beneficiar OR
t.Disccount_acordat	<>tp.Disccount_acordat 

--UPDATE TERTI
SET Denumire=CASE t.Denumire	WHEN ISNULL(NULLIF(tp.Denumire,''),t.Denumire) THEN t.Denumire ELSE tp.Denumire END ,
Cod_fiscal=CASE t.Cod_fiscal	WHEN ISNULL(NULLIF(tp.Cod_fiscal,''),t.Cod_fiscal) THEN t.Cod_fiscal ELSE tp.Cod_fiscal END  ,
Localitate	=CASE t.Localitate	WHEN ISNULL(NULLIF(tp.Localitate,''),t.Localitate) THEN t.Localitate ELSE tp.Localitate END  ,
Judet	=CASE t.Judet	WHEN ISNULL(NULLIF(tp.Judet,''),t.Judet) THEN t.Judet ELSE tp.Judet END  ,
Adresa	=CASE t.Adresa	WHEN ISNULL(NULLIF(tp.Adresa,''),t.Adresa) THEN t.Adresa ELSE tp.Adresa END  ,
Telefon_fax	=CASE t.Telefon_fax	WHEN ISNULL(NULLIF(tp.Telefon_fax,''),t.Telefon_fax) THEN t.Telefon_fax ELSE tp.Telefon_fax END  ,
Banca	=CASE t.Banca	WHEN ISNULL(NULLIF(tp.Banca,''),t.Banca) THEN t.Banca ELSE tp.Banca END  ,
Cont_in_banca	=CASE t.Cont_in_banca	WHEN ISNULL(NULLIF(tp.Cont_in_banca,''),t.Cont_in_banca) THEN t.Cont_in_banca ELSE tp.Cont_in_banca END  ,
Tert_extern	=CASE t.Tert_extern	WHEN ISNULL(NULLIF(tp.Tert_extern,0),t.Tert_extern) THEN t.Tert_extern ELSE tp.Tert_extern END  ,
Grupa	=CASE t.Grupa	WHEN ISNULL(NULLIF(tp.Grupa,''),t.Grupa) THEN t.Grupa ELSE tp.Grupa END  ,
Cont_ca_furnizor	=CASE t.Cont_ca_furnizor	WHEN ISNULL(NULLIF(tp.Cont_ca_furnizor,''),t.Cont_ca_furnizor) THEN t.Cont_ca_furnizor ELSE tp.Cont_ca_furnizor END  ,
Cont_ca_beneficiar	=CASE t.Cont_ca_beneficiar	WHEN ISNULL(NULLIF(tp.Cont_ca_beneficiar,''),t.Cont_ca_beneficiar) THEN t.Cont_ca_beneficiar ELSE tp.Cont_ca_beneficiar END  ,
Sold_ca_furnizor	=CASE t.Sold_ca_furnizor	WHEN ISNULL(NULLIF(tp.Sold_ca_furnizor,0),t.Sold_ca_furnizor) THEN t.Sold_ca_furnizor ELSE tp.Sold_ca_furnizor END  ,
Sold_ca_beneficiar	=CASE t.Sold_ca_beneficiar	WHEN ISNULL(NULLIF(tp.Sold_ca_beneficiar,0),t.Sold_ca_beneficiar) THEN t.Sold_ca_beneficiar ELSE tp.Sold_ca_beneficiar END  ,
Sold_maxim_ca_beneficiar	=CASE t.Sold_maxim_ca_beneficiar	WHEN ISNULL(NULLIF(tp.Sold_maxim_ca_beneficiar,0),t.Sold_maxim_ca_beneficiar) THEN t.Sold_maxim_ca_beneficiar ELSE tp.Sold_maxim_ca_beneficiar END  ,
Disccount_acordat	=CASE t.Disccount_acordat	WHEN ISNULL(NULLIF(tp.Disccount_acordat,0),t.Disccount_acordat) THEN t.Disccount_acordat ELSE tp.Disccount_acordat END  

from terti t INNER JOIN CLIENTI_FINAL_TERTI  tp ON t.Tert=tp.Tert
WHERE 
t.Denumire	<>tp.Denumire OR
t.Cod_fiscal	<>tp.Cod_fiscal OR
t.Localitate	<>tp.Localitate OR
t.Judet	<>tp.Judet OR
t.Adresa	<>tp.Adresa OR
t.Telefon_fax	<>tp.Telefon_fax OR
t.Banca	<>tp.Banca OR
t.Cont_in_banca	<>tp.Cont_in_banca OR
t.Tert_extern	<>tp.Tert_extern OR
t.Grupa	<>tp.Grupa OR
t.Cont_ca_furnizor	<>tp.Cont_ca_furnizor OR
t.Cont_ca_beneficiar	<>tp.Cont_ca_beneficiar OR
t.Sold_ca_furnizor	<>tp.Sold_ca_furnizor OR
t.Sold_ca_beneficiar	<>tp.Sold_ca_beneficiar OR
t.Sold_maxim_ca_beneficiar	<>tp.Sold_maxim_ca_beneficiar OR
t.Disccount_acordat	<>tp.Disccount_acordat 


select * from CLIENTI_FINAL_TERTI c
where c.Cont_ca_beneficiar not in (select cont from conturi)
or c.Cont_ca_furnizor not in (select cont from conturi)

select * from terti_dublati
where SESTERGE='' and RAMANE=''
and tert  in 
(select tert from con c where tip in ('BF','FA')
union all
select furnizor from nomencl)
and tert in 
(select tert from terti)

--UPDATE terti_dublati
SET SESTERGE=''
WHERE TERT IN
('RO16569666   ',
'FR59422256180',
'RO6501825    ')

select * from terti_dublati 
where SESTERGE='1'
and tert in 
(select tert from terti)

select * from terti_dublati
where tert like 'RO6501825%'
denumire like 'gaz%'

----DELETE terti 
from terti join terti_dublati on terti.Tert=terti_dublati.Tert
where SESTERGE='' and RAMANE=''
and terti.tert not in 
(select tert from con c where tip in ('BF','FA')
union all
select furnizor from nomencl)
and tert in 
(select tert from terti)

--INSERT terti
select * from TERTI_PUTINIDX
where tert not in 
(select tert from terti)

select * from terti
where tert like '%D'
and DENUMIRE IN 
(select DENUMIRE from terti  where tert not like '%D')
and tert NOT IN 
(select tert from con c where tip in ('BF','FA')
union all
select furnizor from nomencl)

--select * from targetag
select *
	--Agent	char	30
	--Client	char	30
	--Produs	char	30
	--UM	char	5
	--Data_lunii	datetime	8
	--Comision_suplimentar	float	8
from CLIENTI_PUTINI

--DELETE TERTI
WHERE TERT NOT IN 
(SELECT TERT FROM terti_vechi)

select denumire from terti
group by denumire
having COUNT(*)>1

select * from terti where cod_fiscal in
(select Cod_fiscal
from terti
group by Cod_fiscal
having COUNT(*)>1)
and tert not in
(select tert from con c where tip in ('BF','FA')
union all
select furnizor from nomencl)
and cod_fiscal IN 
(select cod_fiscal from terti  where tert not like '%D')
and tert like '%D'
ORDER BY Cod_fiscal

select * from terti where cod_fiscal in
(select Cod_fiscal
from terti
group by Cod_fiscal
having COUNT(*)>1)
and tert not in
(select tert from con c where tip in ('BF','FA')
union all
select furnizor from nomencl)
ORDER BY Cod_fiscal

--UPDATE nomencl
set Furnizor=left(t.cod_fiscal,13)
from nomencl n join terti t on n.Furnizor=t.Tert

select left(Cod_fiscal,13)
from terti
group by left(Cod_fiscal,13)
having COUNT(*)>1

--UPDATE con
set tert=left(t.cod_fiscal,13)
from con n join terti t on n.tert=t.Tert

--UPDATE pozcon
set tert=left(t.cod_fiscal,13)
from pozcon n join terti t on n.tert=t.Tert

--UPDATE pozdoc
set tert=left(t.cod_fiscal,13)
from pozdoc n join terti t on n.tert=t.Tert

--UPDATE terti
set tert=left(cod_fiscal,13)

--UPDATE infotert
set tert=left(t.cod_fiscal,13)
from infotert n join TEST..terti t on n.tert=t.Tert
join terti tt on t.Cod_fiscal=tt.Cod_fiscal

--DELETE infotert
where tert not in 
(select tert from test..terti
where Cod_fiscal  in (select Cod_fiscal from terti))

--DELETE infotert
where tert like '%d'
(select tert from test..terti
where Cod_fiscal  in (select Cod_fiscal from terti))

select left(Cod_fiscal,13)
from infotert
group by left(Cod_fiscal,13)
having COUNT(*)>1

select tert,Identificator
from infotert
group by tert,Identificator
having COUNT(*)>1

select * from terti

 select left(t.cod_fiscal,13),identificator,MAX(n.tert)
from infotert n join TEST..terti t on n.tert=t.Tert
join terti tt on t.Cod_fiscal=tt.Cod_fiscal
group by left(t.cod_fiscal,13),identificator
having COUNT(*)>1

--DELETE infotert
--INSERT infotert
select * from test..infotert

select *
into infotert_vechi
from infotert

select * from targetag
----TRUNCATE table targetag
----INSERT targetag
SELECT --*,
LEFT(ISNULL(LM.COD,REPLACE(CLIENTI_PUTINI.Loc_de_munca,',','')),30)	--Agent	char	30
,LEFT(ISNULL(NULLIF(REPLACE(Cod_fiscal,'.',''),''),ISNULL(NULLIF(REPLACE(TAX_REFERENCE,'.',''),''),Subunitate)),13)	--Client	char	30
,''	--Produs	char	30
,''	--UM	char	5
,'2012-01-01'	--Data_lunii	datetime	8
,CONVERT(FLOAT,TARGET)	--Comision_suplimentar	float	8
from CLIENTI_PUTINI LEFT JOIN LM ON REPLACE(CLIENTI_PUTINI.Loc_de_munca,',','')=lm.Denumire
WHERE Cod_fiscal<>''
AND CONVERT(FLOAT,TARGET)<>0

,LEFT(ISNULL((SELECT MAX(cod) FROM lm WHERE denumire=REPLACE(LOC_MUNCA,',','')),REPLACE(LOC_MUNCA,',','')),9)

SELECT  
----UPDATE CLIENTI_PUTINI 
--SET 
Loc_de_munca
--='COVERCA FLORIN-SEBAS'
FROM CLIENTI_PUTINI 

WHERE Loc_de_munca LIKE 'VARL%'

--SELECT  
--UPDATE CLIENTI_PUTINI 
SET 
Loc_de_munca
='VARLAN GEORGE-VLADUT'
FROM CLIENTI_PUTINI 

WHERE Loc_de_munca LIKE 'VARL%'

select * from infotert

select *
from infotert i join terti t on i.Tert=t.Tert and i.Identificator=''
where t.Cont_in_banca<>i.Banca3 and replace(replace(replace(t.Cont_in_banca,'.',''),'j',''),'0','')<>''

--UPDATE infotert
set Banca3=left(t.Cont_in_banca,20)
from infotert i join terti t on i.Tert=t.Tert and i.Identificator=''
where t.Cont_in_banca<>i.Banca3 and replace(replace(replace(t.Cont_in_banca,'.',''),'j',''),'0','')<>''

--INSERT infotert
select
Subunitate--Subunitate	char	no	9	     
,Tert --Tert	char	no	13	     
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
,left(t.Cont_in_banca,20) --Banca3	char	no	20	     
,'' --Cont_in_banca3	char	no	35	     
,0 --Indicator	bit	no	1	     
,'' --Grupa13	char	no	13	     
,0 --Sold_ben	float	no	8	53   
,0 --Discount	real	no	4	24   
,0 --Zile_inc	smallint	no	2	5    
,'' --Observatii	char	no	30	 
FROM terti t
where tert not in 
(select tert from infotert where Identificator='') 

select --top 0
* 
--into CLIENTI_SOLD_FACTIMPL
from test..factimpl

--TRUNCATE TABLE CLIENTI_SOLD_FACTIMPL
--INSERT CLIENTI_SOLD_FACTIMPL
SELECT --*,
'1'	--Subunitate	char	9
,'1'	--Loc_de_munca	char	9
,0x46	--Tip	binary	1
--,'IMPL'+LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)	--Factura	char	25
,RTRIM(LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13))+RIGHT(RTRIM(cs.[cont contabil]),7)--LTRIM(CONVERT(CHAR,ROW_NUMBER() OVER(PARTITION BY cs.cod_fiscal, cs.[cont contabil] ORDER BY CS.[sold dec 2011] DESC)))
,LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)	--Tert	char	13
,'2011-12-31'	--Data	datetime	8
,'2011-12-31'	--Data_scadentei	datetime	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold dec 2011],',','')))	--Valoare	float	8
,0	--TVA_11	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold dec 2011],',',''))*(0))	--TVA_22	float	8
,''	--Valuta	char	3
,0	--Curs	float	8
,0	--Valoare_valuta	float	8
,0	--Achitat	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold dec 2011],',','')))	--Sold	float	8
,CASE LEFT(cs.[cont contabil],13) WHEN '4111' THEN '411.1' WHEN '4113' THEN '411.3' ELSE '' END	--Cont_de_tert	char	13
,0	--Achitat_valuta	float	8
,0	--Sold_valuta	float	8
,''	--Comanda	char	40
,''	--Data_ultimei_achitari	datetime	8
	-- SELECT *
FROM CLIENTI_SOLD CS
WHERE cod_fiscal<>''  AND CONVERT(FLOAT,REPLACE(CS.[sold dec 2011],',',''))>0.001
GROUP BY CS.cod_fiscal,CS.[cont contabil]

select --top 0
* 
--into CLIENTI_SOLD_FACTIMPL
from test..factimpl

--TRUNCATE TABLE FACTIMPL
--INSERT factimpl
select * from CLIENTI_SOLD_FACTIMPL

select * from terti where Cod_fiscal like '%1761113345380%'

select top 0 *
INTO CLIENTI_SOLD_LIPSA
FROM terti

--TRUNCATE table CLIENTI_SOLD_LIPSA
--INSERT CLIENTI_SOLD_LIPSA
SELECT --*,
'1'	--Subunitate	char	9
,LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)	--Tert	char	13
,LEFT(CS.CLIENT,80 )	--Denumire	char	80
,LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)	--Cod_fiscal	char	16
,LEFT(CS.localitate,35)	--Localitate	char	35
,LEFT(CS.judet,20)	--Judet	char	20
,LEFT(CS.adresa,60)	--Adresa	char	60
,''	--Telefon_fax	char	20
,''	--Banca	char	20
,''	--Cont_in_banca	char	35
,CASE LEFT(cs.[cont contabil],13) WHEN '4111' THEN 0 WHEN '4113' THEN 1 ELSE '' END		--Tert_extern	bit	1
,LEFT(ISNULL((SELECT MAX(G.GRUPA) FROM gterti G WHERE G.Denumire
	=CASE WHEN SIC_CODE=SIC_CODE_TYPE THEN REPLACE(SIC_CODE,'0','') 
	ELSE LEFT(RTRIM(REPLACE(SIC_CODE,'0',''))+' '+LTRIM(REPLACE(SIC_CODE_TYPE,'0','')),30) END)
	,CASE WHEN SIC_CODE=SIC_CODE_TYPE THEN REPLACE(SIC_CODE,'0','') 
	ELSE LEFT(RTRIM(REPLACE(SIC_CODE,'0',''))+' '+LTRIM(REPLACE(SIC_CODE_TYPE,'0','')),30) END),3) 	--Grupa	char	3
,'401.3'	--Cont_ca_furnizor	char	13
,CASE LEFT(cs.[cont contabil],13) WHEN '4111' THEN '411.1' WHEN '4113' THEN '411.3' ELSE '' END		--Cont_ca_beneficiar	char	13
,0	--Sold_ca_furnizor	float	8
,0	--Sold_ca_beneficiar	float	8
,CONVERT(INT,[limita credit])--Sold_maxim_ca_beneficiar	float	no	8	53   
,CONVERT(INT,REPLACE(REPLACE(REPLACE(CS.[termem plata],'ZILE',''),'ZILLE',''),'IMEDIAT','0')) --Disccount_acordat	real	no	4	24  
	-- SELECT *
FROM CLIENTI_SOLD CS
where cs.cod_fiscal<>''
--WHERE LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13) NOT IN 
--(SELECT TERT FROM TERTI)

--INSERT TERTI
SELECT * FROM CLIENTI_SOLD_LIPSA where tert not in 
(SELECT TERT FROM TERTI)


SELECT ROW_NUMBER() over(order by [Tip client]) cod,
--isnull(nullif(nullif(cl.[Tip client],'#N/A'),''),'FARA GRUPA') 
cl.[Tip client]
INTO CLIENTI_FINAL_GRUPE
FROM CLIENTI_FINAL CL
where CL.[Tip client] NOT IN ('','#N/A')
group by cl.[Tip client]

--TRUNCATE table gterti
--INSERT gterti
select LEFT(c.cod,3),LEFT(c.[Tip client],30),0 from CLIENTI_FINAL_GRUPE c

select top 0 *
INTO CLIENTI_FINAL_TERTI
FROM terti

--TRUNCATE table CLIENTI_FINAL_TERTI
--INSERT CLIENTI_FINAL_TERTI
select
'1'--Subunitate	char	no	9	     
,LEFT(ISNULL(NULLIF(REPLACE(REPLACE(Cod_fiscal,'.',''),' ',''),''),ISNULL(NULLIF(REPLACE(REPLACE(TAX_REFERENCE,'.',''),' ',''),''),Subunitate)),13) --Tert	char	no	13	     
,LEFT(CLIENT,80)--Denumire	char	no	80	     
,LEFT(ISNULL(NULLIF(REPLACE(Cod_fiscal,'.',''),''),ISNULL(NULLIF(REPLACE(TAX_REFERENCE,'.',''),''),Subunitate)),16)--Cod_fiscal	char	no	16	     
,ISNULL((SELECT MAX(l.cod_oras) FROM Localitati L where l.oras like cl.localitate),LEFT(cl.localitate,35))--Localitate	char	no	35	     
,LEFT(CL.judet,20)--Judet	char	no	20	     
,LEFT(CL.adresa,60) --Adresa	char	no	60	     
,''--Telefon_fax	char	no	20	     
,''--Banca	char	no	20	     
,'' --Cont_in_banca	char	no	35	     
,CASE cl.[cont contabil] WHEN '4111' THEN 0 WHEN '4113' THEN 1 ELSE 0 END	--Tert_extern	bit	no	1	     
,LEFT(ISNULL((SELECT MAX(G.GRUPA) FROM gterti G WHERE G.Denumire=CL.[Tip client]),''),3) --Grupa	char	no	3	     
,'401.3'--Cont_ca_furnizor	char	no	13	     
,CASE cl.[cont contabil] WHEN '4111' THEN '411.1' WHEN '4113' THEN '411.3' ELSE '0' END --Cont_ca_beneficiar	char	no	13	     
,0 --Sold_ca_furnizor	float	no	8	53   
,CONVERT(FLOAT,REPLACE(Cl.[sold dec 2011] ,',','')) --Sold_ca_beneficiar	float	no	8	53   
,CONVERT(INT,[limita credit])--Sold_maxim_ca_beneficiar	float	no	8	53   
,0 --Disccount_acordat	real	no	4	24   
--SELECT  * 
FROM CLIENTI_FINAL CL
WHERE cod_fiscal<>''

--UPDATE terti
set Disccount_acordat=0

--INSERT terti
select c.* from CLIENTI_FINAL_TERTI c
where c.Tert not in (select tert from terti)


SELECT TOP 0 * 
INTO AGENTI_CLIENTI_FINAL_INFOTERT
FROM INFOTERT


--TRUNCATE TABLE AGENTI_CLIENTI_FINAL_INFOTERT
--INSERT AGENTI_CLIENTI_FINAL_INFOTERT
select
'1'--Subunitate	char	no	9	     
,LEFT(REPLACE(LTRIM(RTRIM(cl.cod_fiscal)),' ',''),13)	--Tert	char	no	13	     
,'' --Identificator	char	no	5	     
,''	--Descriere	char	no	30	     
--,LEFT(ISNULL((SELECT MAX(cod) FROM lm WHERE denumire=REPLACE(LOC_MUNCA,',','')),REPLACE(LOC_MUNCA,',','')),9) --Loc_munca	char	no	9	     
,'1VNZ0'+LEFT(cl.[Cod AgV],4)
,'' --Pers_contact	char	no	20	     
,'' --Nume_delegat	char	no	30	     
,'' --Buletin	char	no	12	     
,'' --Eliberat	char	no	30	     
,'' --Mijloc_tp	char	no	20	     
,'' --Adresa2	char	no	20	     
,'' --Telefon_fax2	char	no	20	     
,'' --e_mail	char	no	50	     
,'' --Banca2	char	no	20	     
,''--Cont_in_banca2	char	no	35	     
,LEFT(LTRIM(cl.TAX_REFERENCE),20) --Banca3	char	no	20	     
,LEFT(LTRIM(cl.email),35) --Cont_in_banca3	char	no	35	     
,0 --Indicator	bit	no	1	     
,'' --Grupa13	char	no	13	     
,0 --Sold_ben	float	no	8	53   
,CONVERT(INT,REPLACE(REPLACE(REPLACE(cl.[termem plata],'ZILE',''),'ZILLE',''),'IMEDIAT','0')) --Discount	real	no	4	24   
,CASE cl.[cont contabil] WHEN '4111' THEN 0 WHEN '4113' THEN 1 ELSE 0 END --Zile_inc	smallint	no	2	5    
,'' --Observatii	char	no	30	   
-- SELECT *
FROM CLIENTI_FINAL  cl
WHERE cl.cod_fiscal<>''

--INSERT INFOTERT
SELECT * FROM AGENTI_CLIENTI_FINAL_INFOTERT a
WHERE NOT EXISTS (SELECT 1 FROM INFOTERT I WHERE i.tert=a.Tert and i.Identificator='')

--UPDATE infotert
set  Discount=CASE t.Discount WHEN ISNULL(NULLIF(tp.Discount,''),t.Discount) THEN t.Discount ELSE tp.Discount END
from infotert t join AGENTI_CLIENTI_FINAL_INFOTERT tp on t.Tert=tp.Tert and t.Identificator=tp.Identificator
where t.Identificator=''

select * 
into infotert_loc_sters
from infotert where Identificator<>'' and e_mail=''

----DELETE infotert
--from infotert where Identificator<>'' and e_mail=''


SELECT TOP 0 * 
INTO CLIENTI_FINAL_ECHIPE
FROM proprietati

--TRUNCATE TABLE CLIENTI_FINAL_ECHIPE
--INSERT CLIENTI_FINAL_ECHIPE
SELECT
'TERT' --Tip	char	no	20	     
,CASE WHEN LEN(CL.cod_fiscal)<=13 THEN LEFT(CL.cod_fiscal,13) ELSE RIGHT(RTRIM(CL.cod_fiscal),13) END --Cod	char	no	20	     
,'ECHIPA' --Cod_proprietate	char	no	20	     
--,(select MAX(v.valoare) from valproprietati v where v.Cod_proprietate='ECHIPA' and v.Descriere like left(cl.Echipa,80))--Valoare	char	no	200	     
,LEFT(CL.ECHIPA,200)
,'' --Valoare_tupla	char	no	200	     
FROM CLIENTI_FINAL CL
WHERE cod_fiscal<>''

--DELETE proprietati
WHERE TIP='TERT' AND Cod_proprietate='ECHIPA'

--INSERT proprietati
SELECT * FROM CLIENTI_FINAL_ECHIPE

SELECT Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla
FROM CLIENTI_FINAL_ECHIPE
GROUP BY Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla
HAVING COUNT(*)>1

select top 0 *
into ECHIPE_CLIENTI_FINAL
from valproprietati

--TRUNCATE TABLE ECHIPE_CLIENTI_FINAL
--INSERT ECHIPE_CLIENTI_FINAL
select DISTINCT
'ECHIPA' --Cod_proprietate	char	20
--,ROW_NUMBER() OVER(ORDER BY CL.ECHIPA)	--Valoare	char	200
,LEFT(CL.ECHIPA,200)	
,LEFT(CL.ECHIPA,80)	--Descriere	char	80
,''	--Valoare_proprietate_parinte	char	200
from CLIENTI_FINAL CL
GROUP BY CL.ECHIPA

--DELETE valproprietati where Cod_proprietate='ECHIPA'
--INSERT valproprietati
SELECT * from ECHIPE_CLIENTI_FINAL

select * from CLIENTI_FINAL_TERTI C 
LEFT JOIN (select tert, sum(sold) as sold from (select tert, sum(sold)as sold from factimpl group by tert union all 
select tert, sum(sold) from efimpl group by tert) drv group by tert) f on f.Tert=c.Tert
WHERE  C.Sold_ca_beneficiar>0 AND c.Sold_ca_beneficiar<>ISNULL(f.Sold,0)

select --top 0
* 
into factimpl_copie1
from test..factimpl

--TRUNCATE TABLE CLIENTI_FINAL_FACTIMPL
--INSERT CLIENTI_FINAL_FACTIMPL
SELECT --*,
'1'	--Subunitate	char	9
,'1'	--Loc_de_munca	char	9
,0x46	--Tip	binary	1
--,'IMPL'+LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13)	--Factura	char	25
,RTRIM(LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13))+RIGHT(RTRIM(cs.[cont contabil]),7)
--LTRIM(CONVERT(CHAR,ROW_NUMBER() OVER(PARTITION BY cs.cod_fiscal, cs.[cont contabil] ORDER BY CS.[sold dec 2011] DESC)))
,ISNULL((SELECT MAX(t.tert) from terti t where t.Cod_fiscal like max(CS.cod_fiscal) or t.Denumire like max(cs.CLIENT)),
LEFT(REPLACE(LTRIM(RTRIM(CS.cod_fiscal)),' ',''),13))	--Tert	char	13
,'2011-12-31'	--Data	datetime	8
,'2011-12-31'	--Data_scadentei	datetime	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold dec 2011],',','')))	--Valoare	float	8
,0	--TVA_11	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold dec 2011],',',''))*(0))	--TVA_22	float	8
,''	--Valuta	char	3
,0	--Curs	float	8
,0	--Valoare_valuta	float	8
,0	--Achitat	float	8
,SUM(CONVERT(FLOAT,REPLACE(CS.[sold dec 2011],',','')))	--Sold	float	8
,CASE LEFT(cs.[cont contabil],13) WHEN '4111' THEN '411.1' WHEN '4113' THEN '411.3' ELSE '' END	--Cont_de_tert	char	13
,0	--Achitat_valuta	float	8
,0	--Sold_valuta	float	8
,''	--Comanda	char	40
,''	--Data_ultimei_achitari	datetime	8
	-- SELECT *
FROM CLIENTI_FINAL CS
WHERE cod_fiscal<>''  AND CONVERT(FLOAT,REPLACE(CS.[sold dec 2011],',',''))>0.001
GROUP BY CS.cod_fiscal,CS.[cont contabil]

--TRUNCATE table factimpl_copie1 
--INSERT factimpl_copie1
select * from CLIENTI_FINAL_FACTIMPL

--INSERT factimpl_copie1
select * from CLIENTI_SOLD_FACTIMPL c where not exists (select 1 from factimpl_copie1 f where f.Factura=c.Factura and f.Tert=c.Tert)
-- create unique clustered index Unic on factimpl_copie1 (Subunitate, Tip, Factura, Tert)

select * from factimpl_copie1
where tert not in (select t.tert from terti t)

select * from targetag
--TRUNCATE table targetag
--INSERT targetag
SELECT --*,
'1VNZ0'+LTRIM(LEFT(C.[COD AGV],4))	--Agent	char	30
,LEFT(ISNULL(NULLIF(REPLACE(Cod_fiscal,'.',''),''),ISNULL(NULLIF(REPLACE(TAX_REFERENCE,'.',''),''),Subunitate)),13)	--Client	char	30
,LEFT(ISNULL((SELECT MAX(G.GRUPA) FROM gterti G WHERE G.Denumire=C.[Tip client]),''),3)	--Produs	char	30
,''	--UM	char	5
,'2012-01-01'	--Data_lunii	datetime	8
,CONVERT(FLOAT,TARGET)	--Comision_suplimentar	float	8
	-- SELECT *
from CLIENTI_FINAL C 
--LEFT JOIN LM ON  LM.COD --REPLACE(CLIENTI_PUTINI.Loc_de_munca,',','')=lm.Denumire
WHERE Cod_fiscal<>''
AND CONVERT(FLOAT,TARGET)<>0


select t.denumire from terti t
group by t.Denumire
having COUNT(*)>1

----TRUNCATE table terti_final_sters
----INSERT into terti_final_sters
select * from terti t
where t.tert not in (select f.tert from facturi f)
and t.Tert not in (select n.furnizor from nomencl n)
and t.Tert not in (select p.tert from pozcon p)
and t.Tert not in (select e.tert from efecte e)
and t.tert not in (select p.tert from pozdoc p)
and t.Denumire in 
(select t.denumire from terti t
group by t.Denumire
having COUNT(*)>1)

----DELETE terti
--from terti t
--where t.tert not in (select f.tert from facturi f)
--and t.Tert not in (select n.furnizor from nomencl n)
--and t.Tert not in (select p.tert from pozcon p)
--and t.Tert not in (select e.tert from efecte e)
--and t.tert not in (select p.tert from pozdoc p)
--and t.Denumire in 
--(select t.denumire from terti t
--group by t.Denumire
--having COUNT(*)>1)

----INSERT terti
select * from terti_final_sters
where tert not in (select tert from terti)

----INSERT terti
select * from test..terti
where tert not in (select tert from terti)

select * 
into terti_neclienti_final_sters
from terti t
where t.Tert not in (select c.tert from CLIENTI_FINAL_TERTI c)
and t.tert not in (select f.tert from facturi f)
and t.Tert not in (select n.furnizor from nomencl n)
and t.Tert not in (select p.tert from pozcon p where p.Tip IN ('FA','FC','BK'))
and t.Tert not in (select e.tert from efecte e)
and t.tert not in (select p.tert from pozdoc p)

and t.Tert in (select p.tert from pozcon p where p.Tip IN ('BF'))
and t.Denumire in 
(select t.denumire from terti t
group by t.Denumire
having COUNT(*)>1)

----DELETE terti
--from terti t join terti_neclienti_final_sters ts on ts.Tert=t.Tert

select * 
into pozcon_neclienti_final_sters
from pozcon p where p.Tert not in (select tert from terti)

select * from terti_neclienti_final_sters where tert like 'EL094141319'

--DELETE pozcon
from pozcon p where p.Tert not in (select tert from terti)

select * 
into con_neclienti_final_sters
from con p where p.Tert not in (select tert from terti)

--DELETE con
from con p where p.Tert not in (select tert from terti)

select * 
into infotert_neclienti_final_sters
from infotert p where p.Tert not in (select tert from terti)

--DELETE infotert
from infotert p where p.Tert not in (select tert from terti)

select * 
into proprietati_neclienti_final_sters
from proprietati p where p.Tip='TERT' and p.Cod not in (select tert from terti)

--DELETE proprietati
from proprietati p where p.Tip='TERT' and p.Cod not in (select tert from terti)

select t.Cod_fiscal from terti t
group by t.Cod_fiscal
having COUNT(*)>1

--UPDATE terti
set Adresa=UPPER(adresa)

select * 
--into terti_neclienti_final_sters
from terti t
where 
t.Tert not in (select c.tert from CLIENTI_FINAL_TERTI c)  
--t.DENUMIRE  in (select c.Denumire from CLIENTI_FINAL_TERTI c)
and (t.tert in (select f.tert from facturi f where f.Tip=0x46)
--and t.Tert not in (select n.furnizor from nomencl n)
or t.Tert in (select p.tert from pozcon p where p.Tip IN ('BK'))
or t.Tert in (select e.tert from efecte e where e.Tip='i')
or t.tert in (select p.tert from pozdoc p where p.Tip in ('AP')))

-----------------------------------------------------------------------------------------------------------------------------


select top 0 *
INTO CLIENTI_FINAL_COMPLETAT_TERTI
FROM terti

-- 
-- TRUNCATE table CLIENTI_FINAL_COMPLETAT_TERTI INSERT CLIENTI_FINAL_COMPLETAT_TERTI
select
'1'--Subunitate	char	no	9	     
,LEFT(ISNULL(NULLIF(REPLACE(REPLACE(Cod_fiscal,'.',''),' ',''),''),ISNULL(NULLIF(REPLACE(REPLACE(cl.cod_fiscal,'.',''),' ',''),''),client)),13) --Tert	char	no	13	     
,LEFT(CLIENT,80)--Denumire	char	no	80	     
,LEFT(ISNULL(NULLIF(REPLACE(Cod_fiscal,'.',''),''),ISNULL(NULLIF(REPLACE(cod_fiscal,'.',''),''),client)),16)--Cod_fiscal	char	no	16	     
,''--ISNULL((SELECT MAX(l.cod_oras) FROM Localitati L where l.oras like cl.localitate),LEFT(cl.localitate,35))--Localitate	char	no	35	     
,''--LEFT(CL.judet,20)--Judet	char	no	20	     
,''--LEFT(CL.adresa,60) --Adresa	char	no	60	     
,''--Telefon_fax	char	no	20	     
,''--Banca	char	no	20	     
,'' --Cont_in_banca	char	no	35	     
,''--CASE cl.[cont contabil] WHEN '4111' THEN 0 WHEN '4113' THEN 1 ELSE 0 END	--Tert_extern	bit	no	1	     
,LEFT(ISNULL((SELECT MAX(G.GRUPA) FROM gterti G WHERE G.Denumire=CL.[Tip client]),''),3) --Grupa	char	no	3	     
,'401.3'--Cont_ca_furnizor	char	no	13	     
,'411.1'--CASE cl.[cont contabil] WHEN '4111' THEN '411.1' WHEN '4113' THEN '411.3' ELSE '0' END --Cont_ca_beneficiar	char	no	13	     
,0 --Sold_ca_furnizor	float	no	8	53   
,1--CONVERT(FLOAT,REPLACE(Cl.[sold dec 2011] ,',','')) --Sold_ca_beneficiar	float	no	8	53   
,CONVERT(INT,CASE ISNUMERIC(replace(cl.[lcredit  ron],',','')) WHEN 1 THEN replace(cl.[lcredit  ron],',','') ELSE 0 END)--Sold_maxim_ca_beneficiar	float	no	8	53   
,0 --Disccount_acordat	real	no	4	24   
-- SELECT  * 
FROM CLIENTI_FINAL_COMPLETAT CL
WHERE cl.cod_fiscal<>''

select * from terti
--UPDATE terti
set Disccount_acordat=0

--INSERT terti
select c.* from CLIENTI_FINAL_COMPLETAT_TERTI c
where c.Tert not in (select tert from terti)
and c.denumire not in (select t.denumire from terti t)

select * from CLIENTI_FINAL_COMPLETAT_TERTI C WHERE C.TERT='RO28002028'

--update terti
set Sold_maxim_ca_beneficiar=0

--update terti
set Sold_maxim_ca_beneficiar=c.Sold_maxim_ca_beneficiar
from terti t inner join CLIENTI_FINAL_COMPLETAT_TERTI c on c.tert=t.tert

SELECT TOP 0 * 
INTO AGENTI_CLIENTI_FINAL_COMPLETAT_INFOTERT
FROM INFOTERT


-- TRUNCATE TABLE AGENTI_CLIENTI_FINAL_COMPLETAT_INFOTERT INSERT AGENTI_CLIENTI_FINAL_COMPLETAT_INFOTERT
select
'1'--Subunitate	char	no	9	     
,LEFT(REPLACE(LTRIM(RTRIM(cl.cod_fiscal)),' ',''),13)	--Tert	char	no	13	     
,'' --Identificator	char	no	5	     
,''	--Descriere	char	no	30	     
--,LEFT(ISNULL((SELECT MAX(cod) FROM lm WHERE denumire=REPLACE(LOC_MUNCA,',','')),REPLACE(LOC_MUNCA,',','')),9) --Loc_munca	char	no	9	     
,'1VNZ0'+LEFT(cl.[Cod AgV],4)
,'' --Pers_contact	char	no	20	     
,'' --Nume_delegat	char	no	30	     
,'' --Buletin	char	no	12	     
,'' --Eliberat	char	no	30	     
,'' --Mijloc_tp	char	no	20	     
,'' --Adresa2	char	no	20	     
,'' --Telefon_fax2	char	no	20	     
,'' --e_mail	char	no	50	     
,'' --Banca2	char	no	20	     
,''--Cont_in_banca2	char	no	35	     
,''--LEFT(LTRIM(cl.TAX_REFERENCE),20) --Banca3	char	no	20	     
,''--LEFT(LTRIM(cl.email),35) --Cont_in_banca3	char	no	35	     
,0 --Indicator	bit	no	1	     
,'' --Grupa13	char	no	13	     
,0 --Sold_ben	float	no	8	53   
,0--CONVERT(INT,REPLACE(REPLACE(REPLACE(cl.[termem plata],'ZILE',''),'ZILLE',''),'IMEDIAT','0')) --Discount	real	no	4	24   
,0--CASE cl.[cont contabil] WHEN '4111' THEN 0 WHEN '4113' THEN 1 ELSE 0 END --Zile_inc	smallint	no	2	5    
,'' --Observatii	char	no	30	   
-- SELECT *
FROM CLIENTI_FINAL_COMPLETAT  cl
WHERE cl.cod_fiscal<>''

--INSERT INFOTERT
SELECT * FROM AGENTI_CLIENTI_FINAL_COMPLETAT_INFOTERT a
WHERE NOT EXISTS (SELECT 1 FROM INFOTERT I WHERE i.tert=a.Tert and i.Identificator='')

--UPDATE infotert
set  Loc_munca=CASE t.Loc_munca WHEN ISNULL(NULLIF(tp.Loc_munca,''),t.Loc_munca) THEN t.Loc_munca ELSE tp.Loc_munca END
from infotert t join AGENTI_CLIENTI_FINAL_COMPLETAT_INFOTERT tp on t.Tert=tp.Tert and t.Identificator=tp.Identificator
where t.Identificator=''

select * 
into infotert_loc_sters
from infotert where Identificator<>'' and e_mail=''

----DELETE infotert
--from infotert where Identificator<>'' and e_mail=''


SELECT TOP 0 * 
INTO CLIENTI_FINAL_COMPLETAT_ECHIPE
FROM proprietati

--TRUNCATE TABLE CLIENTI_FINAL_COMPLETAT_ECHIPE INSERT CLIENTI_FINAL_COMPLETAT_ECHIPE
SELECT
'TERT' --Tip	char	no	20	     
,CASE WHEN LEN(CL.cod_fiscal)<=13 THEN LEFT(CL.cod_fiscal,13) ELSE RIGHT(RTRIM(CL.cod_fiscal),13) END --Cod	char	no	20	     
,'ECHIPA' --Cod_proprietate	char	no	20	     
--,(select MAX(v.valoare) from valproprietati v where v.Cod_proprietate='ECHIPA' and v.Descriere like left(cl.Echipa,80))--Valoare	char	no	200	     
,LEFT(CL.ECHIPA,200)
,'' --Valoare_tupla	char	no	200	     
-- select *
FROM CLIENTI_FINAL_COMPLETAT CL
WHERE cod_fiscal<>''

--DELETE proprietati
WHERE TIP='TERT' AND Cod_proprietate='ECHIPA'

--INSERT proprietati
SELECT * FROM CLIENTI_FINAL_COMPLETAT_ECHIPE

SELECT Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla
FROM CLIENTI_FINAL_ECHIPE
GROUP BY Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla
HAVING COUNT(*)>1

select top 0 *
into ECHIPE_CLIENTI_FINAL_COMPLETAT
from valproprietati

--TRUNCATE TABLE ECHIPE_CLIENTI_FINAL_COMPLETAT INSERT ECHIPE_CLIENTI_FINAL_COMPLETAT
select DISTINCT
'ECHIPA' --Cod_proprietate	char	20
--,ROW_NUMBER() OVER(ORDER BY CL.ECHIPA)	--Valoare	char	200
,LEFT(CL.ECHIPA,200)	
,LEFT(CL.ECHIPA,80)	--Descriere	char	80
,''	--Valoare_proprietate_parinte	char	200
from CLIENTI_FINAL_COMPLETAT CL
GROUP BY CL.ECHIPA

--DELETE valproprietati where Cod_proprietate='ECHIPA'
--INSERT valproprietati
SELECT * from ECHIPE_CLIENTI_FINAL_COMPLETAT

select * from CLIENTI_FINAL_TERTI C 
LEFT JOIN (select tert, sum(sold) as sold from (select tert, sum(sold)as sold from factimpl group by tert union all 
select tert, sum(sold) from efimpl group by tert) drv group by tert) f on f.Tert=c.Tert
WHERE  C.Sold_ca_beneficiar>0 AND c.Sold_ca_beneficiar<>ISNULL(f.Sold,0)


select * from targetag
-- TRUNCATE table targetag INSERT targetag
SELECT --*,
'1VNZ0'+LTRIM(LEFT(C.[COD AGV],4))	--Agent	char	30
,LEFT(ISNULL(NULLIF(REPLACE(Cod_fiscal,'.',''),''),ISNULL(NULLIF(REPLACE(cod_fiscal,'.',''),''),'')),13)	--Client	char	30
,LEFT(ISNULL((SELECT MAX(G.GRUPA) FROM gterti G WHERE G.Denumire=C.[Tip client]),''),3)	--Produs	char	30
,''	--UM	char	5
,'2012-01-01'	--Data_lunii	datetime	8
,CONVERT(FLOAT,CASE ISNUMERIC(REPLACE([target ron],',','')) WHEN 1 THEN REPLACE([target ron],',','') ELSE 0 END)	--Comision_suplimentar	float	8
	-- SELECT *
from CLIENTI_FINAL_COMPLETAT C 
--LEFT JOIN LM ON  LM.COD --REPLACE(CLIENTI_PUTINI.Loc_de_munca,',','')=lm.Denumire
WHERE Cod_fiscal<>''
AND CONVERT(FLOAT,CASE ISNUMERIC(REPLACE([target ron],',','')) WHEN 1 THEN REPLACE([target ron],',','') ELSE 0 END)	<>0