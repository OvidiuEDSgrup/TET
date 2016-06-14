SELECT * FROM CLIENTI WHERE CODFISCAL=''
SELECT * FROM CLIENTI WHERE ZONA2<>ZONA
JUDET_REPREZ<>Judet 
OR ZONA2<>ZONA
select * from clienti where codfiscal not like 'R%'
select MAX(len(Adresa)) from clienti
select * from clienti where len(codfiscal)=14

select distinct tipclient from clienti

SELECT MAX(LEN(GRUPA)) FROM CLIENTI

INSERT GTERTI
SELECT
100+ROW_NUMBER() over(order by grupa) --Grupa	char	no	3	     
,LEFT(GRUPA,30) --Denumire	char	no	30	     
,0--Discount_acordat	real	no	4	24   
--id	int	no	4	10   
FROM (select distinct grupa from CLIENTI WHERE GRUPA<>'') as tmp


SELECT TOP 0 * 
INTO CLIENTIDX
FROM TERTI

TRUNCATE TABLE CLIENTIDX
insert CLIENTIDX
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


select REPLACE(LOC_MUNCA,',',''), REPLACE(REPREZENTATNT,',',''),* from clienti

--TRUNCATE TABLE TERTIDX
INSERT TERTIDX
SELECT * FROM CLIENTIDX c
where c.Tert not in (select tert from tertidx)

SELECT TERT FROM TERTIDX GROUP BY TERT HAVING COUNT(*)>1

SELECT * FROM TERTI

TRUNCATE TABLE TERTI
INSERT TERTI
SELECT * FROM TERTIDX

select tert
from tertidx
group by tert having count(*)>1

SELECT * FROM CLIENTIDX
WHERE TERT IN (SELECT TERT FROM FURNIZORIDX)


SELECT TOP 0 * 
INTO PERSONALIDX
FROM PERSONAL

truncate table PERSONAL
INSERT PERSONAL
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

truncate table personal
insert personal 
select * from PERSONALIDX 

SELECT * FROM proprietati WHERE Tip='TERT'

SELECT TOP 0 * 
INTO TIPCLIENTIDX
FROM proprietati

TRUNCATE TABLE TIPCLIENTIDX
INSERT TIPCLIENTIDX
SELECT
'TERT' --Tip	char	no	20	     
,CASE WHEN LEN(CODFISCAL)<=13 THEN LEFT(CODFISCAL,13) ELSE RIGHT(RTRIM(CODFISCAL),13) END --Cod	char	no	20	     
,'TIPCLIENT' --Cod_proprietate	char	no	20	     
,TIPCLIENT --Valoare	char	no	200	     
,'' --Valoare_tupla	char	no	200	     
FROM CLIENTI
WHERE CODFISCAL<>''

DELETE proprietati
WHERE TIP='TERT' AND Cod_proprietate='TIPCLIENT'

INSERT proprietati
SELECT * FROM TIPCLIENTIDX

SELECT Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla
FROM TIPCLIENTIDX
GROUP BY Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla
HAVING COUNT(*)>1

select * from clienti

SELECT TOP 0 * 
INTO AGENTIDX
FROM INFOTERT

TRUNCATE TABLE AGENTIDX
insert AGENTIDX
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

TRUNCATE TABLE INFOTERTIDX
INSERT INFOTERTIDX
SELECT * FROM AGENTIDX

TRUNCATE TABLE INFOTERT
INSERT INFOTERT
SELECT * FROM AGENTIDX 

select * from AGV_ASM_ZONE B INNER JOIN AGV_ASM_ZONE S ON 
B.JGZZ_FISCAL_CODE=S.JGZZ_FISCAL_CODE
WHERE B.SITE='BILL_TO' AND S.SITE='SHIP_TO'


SELECT TOP 0 * 
INTO GRUPECLIENTIDX
FROM proprietati

TRUNCATE TABLE GRUPECLIENTIDX
INSERT GRUPECLIENTIDX
SELECT
'TERT' --Tip	char	no	20	     
,CASE WHEN LEN(CODFISCAL)<=13 THEN LEFT(CODFISCAL,13) ELSE RIGHT(RTRIM(CODFISCAL),13) END --Cod	char	no	20	     
,'GRUPACLIENT' --Cod_proprietate	char	no	20	     
,GRUPA --Valoare	char	no	200	     
,'' --Valoare_tupla	char	no	200	     
FROM CLIENTI
WHERE CODFISCAL<>''

INSERT proprietati
select * from GRUPECLIENTIDX

----------------

SELECT * FROM CLIENTI_PUTINI
GTERTI
SELECT DISTINCT CASE WHEN SIC_CODE=SIC_CODE_TYPE THEN REPLACE(SIC_CODE,'0','') 
ELSE LEFT(RTRIM(REPLACE(SIC_CODE,'0',''))+' '+LTRIM(REPLACE(SIC_CODE_TYPE,'0','')),30) END FROM CLIENTI_PUTINI

SELECT TOP 0 * 
INTO CLIENTI_PUTINIDX
FROM TERTI

TRUNCATE TABLE CLIENTI_PUTINIDX
insert CLIENTI_PUTINIDX
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

--insert terti2
select * from TERTI_PUTINIDX

truncate table terti2
insert terti2
select * from terti t
where t.tert not in 
(select tert from con c where tip in ('BF','FA')
union all
select tert from TERTI_PUTINIDX
union all
select furnizor from nomencl)

--delete t from terti t
where t.tert not in 
(select tert from con c where tip in ('BF','FA')
union all
select tert from TERTI_PUTINIDX
union all
select furnizor from nomencl)


--insert terti_vechi
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
from terti t INNER JOIN TERTI_PUTINIDX tp ON t.Tert=tp.Tert
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

UPDATE TERTI
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

from terti t INNER JOIN TERTI_PUTINIDX tp ON t.Tert=tp.Tert
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


select * from terti_dublati
where SESTERGE='' and RAMANE=''
and tert  in 
(select tert from con c where tip in ('BF','FA')
union all
select furnizor from nomencl)
and tert in 
(select tert from terti)

UPDATE terti_dublati
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

--delete terti 
from terti join terti_dublati on terti.Tert=terti_dublati.Tert
where SESTERGE='' and RAMANE=''
and terti.tert not in 
(select tert from con c where tip in ('BF','FA')
union all
select furnizor from nomencl)
and tert in 
(select tert from terti)

insert terti
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

delete TERTI
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

UPDATE nomencl
set Furnizor=left(t.cod_fiscal,13)
from nomencl n join terti t on n.Furnizor=t.Tert

select left(Cod_fiscal,13)
from terti
group by left(Cod_fiscal,13)
having COUNT(*)>1

UPDATE con
set tert=left(t.cod_fiscal,13)
from con n join terti t on n.tert=t.Tert

UPDATE pozcon
set tert=left(t.cod_fiscal,13)
from pozcon n join terti t on n.tert=t.Tert

UPDATE pozdoc
set tert=left(t.cod_fiscal,13)
from pozdoc n join terti t on n.tert=t.Tert

UPDATE terti
set tert=left(cod_fiscal,13)

UPDATE infotert
set tert=left(t.cod_fiscal,13)
from infotert n join TEST..terti t on n.tert=t.Tert
join terti tt on t.Cod_fiscal=tt.Cod_fiscal

DELETE infotert
where tert not in 
(select tert from test..terti
where Cod_fiscal  in (select Cod_fiscal from terti))

DELETE infotert
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

delete infotert
insert infotert
select * from test..infotert

select *
into infotert_vechi
from infotert

select * from targetag
--truncate table targetag
--insert targetag
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
--UPDATE CLIENTI_PUTINI 
--SET 
Loc_de_munca
--='COVERCA FLORIN-SEBAS'
FROM CLIENTI_PUTINI 

WHERE Loc_de_munca LIKE 'VARL%'

--SELECT  
UPDATE CLIENTI_PUTINI 
SET 
Loc_de_munca
='VARLAN GEORGE-VLADUT'
FROM CLIENTI_PUTINI 

WHERE Loc_de_munca LIKE 'VARL%'

select * from infotert

select *
from infotert i join terti t on i.Tert=t.Tert and i.Identificator=''
where t.Cont_in_banca<>i.Banca3 and replace(replace(replace(t.Cont_in_banca,'.',''),'j',''),'0','')<>''

update infotert
set Banca3=left(t.Cont_in_banca,20)
from infotert i join terti t on i.Tert=t.Tert and i.Identificator=''
where t.Cont_in_banca<>i.Banca3 and replace(replace(replace(t.Cont_in_banca,'.',''),'j',''),'0','')<>''

insert infotert
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