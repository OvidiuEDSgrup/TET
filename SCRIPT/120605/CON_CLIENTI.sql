SELECT distinct VALOARE_ATRIBUT_PRODUS FROM CON_CLIENTI
select distinct GRUPA_VANZARE from NOM_CATEG

select * from grupe
select DISTINCT BRAND from CON_CLIENTI
where BRAND not in (select FURNIZOR from FURNIZORI_NOM_CATEG)

SELECT * FROM FURNIZORI_CON_CLIENTI
SELECT MAX(LEN( REPLACE(REPLACE(LOC_DE_MUNCA,'  ',' '),',',''))) FROM CON_CLIENTI 
WHERE REPLACE(REPLACE(LOC_DE_MUNCA,'  ',' '),',','') NOT IN (SELECT DENUMIRE FROM LM)
select * from grupe
select * from con where tip='bf'

select top 0 * 
into CON_CLIENTIDX
FROM CON

 TRUNCATE TABLE CON_CLIENTIDX 
 insert CON_CLIENTIDX
select --*,
'1' --Subunitate	char	no	9
,'BF' --Tip	char	no	2
,ISNULL(NULLIF(RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),17),''),Contract)+LEFT(MONEDA,2) --Contract	char	no	20
,ISNULL(NULLIF(RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),13),''),Contract) --Tert	char	no	13
,'1' --Punct_livrare	char	no	13
,'2012-01-01' --Data	datetime	no	8
,'1' --Stare	char	no	1
,LEFT(COALESCE(lm.cod,CONVERT(CHAR(9),personal.Marca),i.loc_munca, replace(CON_CLIENTI.Loc_de_munca,',','')),9) --Loc_de_munca	char	no	9
,LEFT(gestiunea,9) --Gestiune	char	no	9
,'2012-01-01' --Termen	datetime	no	8
,CASE ISNUMERIC(REPLACE(REPLACE([termem plata],'zile',''),'IMEDIAT','0')) 
	WHEN 1 THEN CONVERT(smallint,REPLACE(REPLACE([termem plata],'zile',''),'IMEDIAT','0'))
	ELSE 0 END --Scadenta	smallint	no	2
,0 --Discount	real	no	4
,LEFT(MONEDA,3) --Valuta	char	no	3
,0 --Curs	float	no	8
,'' --Mod_plata	char	no	1
,'' --Mod_ambalare	char	no	1
,'' --Factura	char	no	20
,0 --Total_contractat	float	no	8
,0 --Total_TVA	float	no	8
,'' --Contract_coresp	char	no	20
,'' --Mod_penalizare	char	no	13
,0 --Procent_penalizare	real	no	4
,0 --Procent_avans	real	no	4
,0 --Avans	float	no	8
,0 --Nr_rate	smallint	no	2
,0 --Val_reziduala	float	no	8
,0 --Sold_initial	float	no	8
,'' --Cod_dobanda	char	no	20
,0 --Dobanda	real	no	4
,0 --Incasat	float	no	8
--,'nic'
,LEFT(COALESCE(i.descriere,CONVERT(CHAR(20),personal.Marca),lm.cod,replace(CON_CLIENTI.Loc_de_munca,',','')),20) --Responsabil	char	no	20
,LEFT(target,20) --Responsabil_tert	char	no	20
,'' --Explicatii	char	no	50
,'' --Data_rezilierii	datetime	no	8
-- SELECT LEFT(COALESCE(lm.cod,CONVERT(CHAR(9),personal.Marca),i.loc_munca, replace(CON_CLIENTI.Loc_de_munca,',','')),9) ,*
FROM CON_CLIENTI
left join personal on CONVERT(CHAR(50),replace(CON_CLIENTI.Loc_de_munca,',','')) LIKE personal.Nume
left OUTER join lm on lm.Cod like '1VNZ'+ltrim(rtrim(personal.marca))
LEFT JOIN infotert i on i.Tert=ISNULL(NULLIF(RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),13),''),Contract)
	and i.Identificator=''
where cod_fiscal NOT IN ('','0')
--AND CON_CLIENTI.Loc_de_munca LIKE 'STIRBU%'

select distinct REPLACE(Loc_de_munca,',','') 
,LEFT(ISNULL((SELECT MAX(marca) FROM personal WHERE Nume like convert(char(50),ltrim(rtrim(REPLACE(Loc_de_munca,',',''))))),'12345678901234567890'),20) from CON_CLIENTi
where REPLACE(Loc_de_munca,',','')   in (select nume from personal)

DORNEA TRAIAN-ANDREI-MIHAI

select * from personal

delete con
where tip='bf'
INSERT CON
SELECT * FROM CON_CLIENTIDX

select * from con where tip='bf'
select * from pozcon where tip='bf'

select top 0 *
into CON_CLIENTI_TERTI
FROM TERTI

TRUNCATE TABLE CON_CLIENTI_TERTI
INSERT CON_CLIENTI_TERTI
SELECT --*,
'1' --Subunitate	char	no	9
,ISNULL(NULLIF(RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),13),''),Contract)  --Tert	char	no	13
,LEFT(CLIENT,80) --Denumire	char	no	80
,ISNULL(NULLIF(RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),16),''),Contract) --Cod_fiscal	char	no	16
,'' --Localitate	char	no	35
,'' --Judet	char	no	20
,'' --Adresa	char	no	60
,'' --Telefon_fax	char	no	20
,'' --Banca	char	no	20
,'' --Cont_in_banca	char	no	35
,0 --Tert_extern	bit	no	1
,LEFT(ISNULL((SELECT MAX(G.GRUPA) FROM gterti G WHERE G.Denumire=CON_CLIENTI.SIC_CODE),CON_CLIENTI.SIC_CODE),3) --Grupa	char	no	3
,'4012'--Cont_ca_furnizor	char	no	13	     
,'4111'--Cont_ca_beneficiar	char	no	13	  
,0--Sold_ca_furnizor	float	no	8	53   
,0--Sold_ca_beneficiar	float	no	8	53   
,CASE ISNUMERIC( [limita credit]) WHEN 1 THEN CONVERT(INT, [limita credit]) ELSE 0 END --Sold_maxim_ca_beneficiar	float	no	8	53   
,0--Disccount_acordat	real	no	4	24   
FROM CON_CLIENTI
where cod_fiscal NOT IN ('','0')



insert terti
select * from CON_CLIENTI_TERTI
where tert not in (select tert from terti)

update terti
set Sold_maxim_ca_beneficiar=CON_CLIENTI_TERTI.Sold_maxim_ca_beneficiar
from terti join CON_CLIENTI_TERTI on terti.tert=CON_CLIENTI_TERTI.Tert
where terti.Sold_maxim_ca_beneficiar=0 and CON_CLIENTI_TERTI.Sold_maxim_ca_beneficiar>0

SELECT Subunitate, Tip, Data, Contract, Tert
FROM CON_CLIENTIDX
GROUP BY Subunitate, Tip, Data, Contract, Tert
HAVING COUNT(*)>1

select distinct [termem plata] from CON_CLIENTI

select MAX(len(loc_de_munca))
from CON_CLIENTI

select  top 0 *
into POZCON_CLIENTIDXx
FROM POZCON 
WHERE TIP='BF'


TRUNCATE TABLE POZCON_CLIENTIDX
 INSERT POZCON_CLIENTIDX
SELECT --*, 
'1' --Subunitate	char	no	9
,'BF' --Tip	char	no	2
,RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),20) --Contract	char	no	20
,RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),20) --Tert	char	no	13
,'' --Punct_livrare	char	no	13
,'2012-01-01' --Data	datetime	no	8
,ISNULL(proprietati.Cod,'') --Cod	char	no	30
,1 --Cantitate	float	no	8
,COALESCE((select max(preturi.Pret_vanzare) from preturi where preturi.Tip_pret='1' AND preturi.Cod_produs=ISNULL(proprietati.Cod,'') 
	and preturi.UM=CASE LEFT(MONEDA,2) WHEN 'EU' THEN 1 ELSE 2 END),NOmencl.Pret_stoc,0) --Pret	float	no	8
,0 --Pret_promotional	float	no	8
,PROCENT --Discount	real	no	4
,'' --Termen	datetime	no	8
,'101' --Factura	char	no	9
,0 --Cant_disponibila	float	no	8
,1 --Cant_aprobata	float	no	8
,0 --Cant_realizata	float	no	8
,LEFT(MONEDA,3) --Valuta	char	no	3
,24 --Cota_TVA	real	no	4
,0 --Suma_TVA	float	no	8
,'' --Mod_de_plata	char	no	8
,'' --UM	char	no	1
,0 --Zi_scadenta_din_luna	smallint	no	2
,'' --Explicatii	char	no	200
,ROW_NUMBER() OVER(PARTITION BY cod_fiscal ORDER BY POZCON_CLIENTI.VALOARE_ATRIBUT_PRODUS) --Numar_pozitie	int	no	4
,'IMPL' --Utilizator	char	no	10
,GETDATE() --Data_operarii	datetime	no	8
,'' --Ora_operarii	char	no	6
-- select *
FROM POZCON_CLIENTI
JOIN PROPRIETATI ON proprietati.Tip='NOMENCL' AND proprietati.Cod_proprietate='GRUPAVANZARE' 
	AND proprietati.Valoare=POZCON_CLIENTI.VALOARE_ATRIBUT_PRODUS
LEFT JOIN NOMENCL ON NOMENCL.Cod=proprietati.Cod 
	AND (NOMENCL.Furnizor=POZCON_CLIENTI.BRAND OR NOMENCL.Furnizor=POZCON_CLIENTI.codfiscal_BRAND)
	


SELECT * FROM POZCON_CLIENTI

select Subunitate, Tip, Contract, Tert, Cod, Data
from POZCON_CLIENTIDX
group by Subunitate, Tip, Contract, Tert, Cod, Data
having COUNT(*)>1
CREATE NONCLUSTERED INDEX IDX1 ON POZCON_CLIENTIDX	(Subunitate, Tip, Contract, Tert, Cod, Data) 
TRUNCATE TABLE POZCON_CLIENTIDXx
insert POZCON_CLIENTIDXx
select 
Subunitate
,Tip
,Contract
,Tert
,MIN(Punct_livrare)
,Data
,Cod
,MAX(Cantitate)
,MAX(Pret)
,MIN(Pret_promotional)
,SUM(Discount)
,MAX(Termen)
,MAX(Factura)
,MIN(Cant_disponibila)
,MAX(Cant_aprobata)
,MIN(Cant_realizata)
,MAX(Valuta)
,MAX(Cota_TVA)
,MIN(Suma_TVA)
,MIN(Mod_de_plata)
,MAX(UM)
,MAX(Zi_scadenta_din_luna)
,MIN(Explicatii)
,MIN(Numar_pozitie)
,MIN(Utilizator)
,MIN(Data_operarii)
,MIN(Ora_operarii )
from POZCON_CLIENTIDX
group by Subunitate, Tip, Contract, Tert, Cod, Data

SELECT * FROM POZCON_CLIENTIDX

SELECT * FROM proprietati WHERE Cod_proprietate='GRUPAVANZARE'
update POZCON_CLIENTI
set codfiscal_BRAND=ISNULL(FURNIZORI_CON_CLIENTI.CODFISCAL_VAT,'')
FROM POZCON_CLIENTI JOIN FURNIZORI_CON_CLIENTI ON POZCON_CLIENTI.BRAND=FURNIZORI_CON_CLIENTI.BRAND

update POZCON_CLIENTI
set codfiscal_BRAND=ISNULL(codfiscal_BRAND,'')

insert pozcon
select * from POZCON_CLIENTIDXx

UPDATE pozcon
set Pret= COALESCE((select max(preturi.Pret_vanzare) from preturi 
	where preturi.Tip_pret='1' AND preturi.Cod_produs=pozcon.Cod 
	and preturi.UM=CASE LEFT(POZCON.VALUTA,2) WHEN 'EU' THEN 1 ELSE 2 END),nomencl.Pret_stoc,0)
from pozcon left join nomencl on pozcon.cod=nomencl.Cod 
WHERE pozcon.TIP='BF'
and abs(pozcon.Pret)<0.001
--delete pozcon  where tip='bf'

select * from pozcon where tip='bf'
select * from preturi

select * from preturi

update pozcon
from pozcon


update con
set 
--SELECT 
Loc_de_munca=LEFT( CASE WHEN PERSONAL.Marca=CON.Responsabil THEN '1VNZ'+ltrim(con.responsabil) 
						ELSE '1VNZ' END,9)
FROM CON LEFT JOIN PERSONAL ON CON.Responsabil=PERSONAL.Marca
WHERE TIP='BF'						

update
terti
--set 
--SELECT
SET Sold_ca_beneficiar=CASE LEFT(VALUTA,2) WHEN 'EU' THEN 1 WHEN 'US' THEN 2 ELSE 3 END
FROM con inner join terti on con.tert= terti.tert and con.subunitate=terti.subunitate
where con.Tip in ('BF','FA') 

INSERT POZCON
select * from pozcon1 where tip<>'BF'
select * from pozcon1
where contract='15493284'

SELECT * from pozcon p
where not exists 
(select 1 from con c where p.Subunitate=c.Subunitate and p.Tip=c.Tip and p.Tert=c.Tert and p.Contract=c.Contract
and p.Data=c.Data)
and p.Tip in ('BF','FA')

SELECT * FROM con
where Tip in ('BF','FA')

--insert con
select 
p.Subunitate--Subunitate	char	no	9
,p.Tip --Tip	char	no	2
,RTRIM(p.Contract) --Contract	char	no	20
,p.Tert --Tert	char	no	13
,'1' --Punct_livrare	char	no	13
,p.Data --Data	datetime	no	8
,'1' --Stare	char	no	1
,MAX(isnull(i.Loc_munca,'')) --Loc_de_munca	char	no	9
,max(p.factura) --Gestiune	char	no	9
,MAX(p.Termen) --Termen	datetime	no	8
,MAX(isnull(DATEDIFF(d,p.Data,t.data),0)) --Scadenta	smallint	no	2
,MAX(p.Discount) --Discount	real	no	4
,MAX(p.Valuta) --Valuta	char	no	3
,isnull((SELECT TOP 1 curs FROM curs WHERE Valuta=max(p.valuta) and data<=max(p.data) ORDER BY Data DESC),0) --Curs	float	no	8
,'' --Mod_plata	char	no	1
,'' --Mod_ambalare	char	no	1
,'' --Factura	char	no	25
,0 --Total_contractat	float	no	8
,0 --Total_TVA	float	no	8
,'' --Contract_coresp	char	no	20
,'' --Mod_penalizare	char	no	13
,0 --Procent_penalizare	real	no	4
,0 --Procent_avans	real	)no	4
,0 --Avans	float	no	8
,0 --Nr_rate	smallint	no	2
,0 --Val_reziduala	float	no	8
,0 --Sold_initial	float	no	8
,'' --Cod_dobanda	char	no	20
,0 --Dobanda	real	no	4
,0 --Incasat	float	no	8
,MAX(isnull(i.Descriere,'')) --Responsabil	char	no	20
,'' --Responsabil_tert	char	no	20
,'' --Explicatii	char	no	50
,'' --Data_rezilierii	datetime	no	8
--into CON_ALTEVALUTE
from pozcon p left join termene t on p.Subunitate=t.Subunitate and p.Tip=t.Tip and p.Tert=t.Tert and p.Contract=t.Contract
and p.Data=t.Data and p.Cod=t.Cod
left join infotert i on i.Subunitate=p.Subunitate and i.Tert=p.Tert and i.Identificator=''
where not exists 
(select 1 from con c where p.Subunitate=c.Subunitate and p.Tip=c.Tip and p.Tert=c.Tert and p.Contract=c.Contract
and p.Data=c.Data ANd left(p.valuta,2)=left(c.valuta,2))
and p.Tip in ('BF') 
group by p.Subunitate, p.Tip, p.Data, p.Tert, p.Contract

SELECT * FROM INFOTERT 

UPDATE POZCON
SET Contract=isnull((select MAX(contract) from con c where p.Subunitate=c.Subunitate and p.Tip=c.Tip and p.Tert=c.Tert and p.Contract=c.Contract
and p.Data=c.Data ANd p.valuta=c.valuta),p.Contract)
from pozcon p join con c on p.Subunitate=c.Subunitate and p.Tip=c.Tip and p.Tert=c.Tert and p.Contract=c.Contract
and p.Data=c.Data 
where p.Tip in ('BF','FA') 
and p.valuta<>c.valuta

select * from pozcon where Contract like '4'
RO7708854           


select  top 0 *
into POZCON_CLIENTIDXx
FROM POZCON 
WHERE TIP='BF'


TRUNCATE TABLE POZCON_CLIENTIDX
 INSERT POZCON_CLIENTIDX
SELECT --*, 
'1' --Subunitate	char	no	9
,'BF' --Tip	char	no	2
,RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),17)+LEFT(MONEDA,2) --Contract	char	no	20
,RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),20) --Tert	char	no	13
,'' --Punct_livrare	char	no	13
,'2012-01-01' --Data	datetime	no	8
,LEFT(ISNULL((SELECT MAX(CODGRUPAVANZARE) FROM GRUPE_VANZARE WHERE GRUPA_VANZARE LIKE POZCON_CLIENTI.VALOARE_ATRIBUT_PRODUS),''),30) --Cod	char	no	30
,1 --Cantitate	float	no	8
,0 --Pret	float	no	8
,0 --Pret_promotional	float	no	8
,PROCENT --Discount	real	no	4
,'' --Termen	datetime	no	8
,'101' --Factura	char	no	9
,0 --Cant_disponibila	float	no	8
,1 --Cant_aprobata	float	no	8
,0 --Cant_realizata	float	no	8
,LEFT(MONEDA,3) --Valuta	char	no	3
,24 --Cota_TVA	real	no	4
,0 --Suma_TVA	float	no	8
,'G' --Mod_de_plata	char	no	8
,'' --UM	char	no	1
,0 --Zi_scadenta_din_luna	smallint	no	2
,'' --Explicatii	char	no	200
,ROW_NUMBER() OVER(PARTITION BY cod_fiscal ORDER BY POZCON_CLIENTI.VALOARE_ATRIBUT_PRODUS) --Numar_pozitie	int	no	4
,'IMPL' --Utilizator	char	no	10
,GETDATE() --Data_operarii	datetime	no	8
,'' --Ora_operarii	char	no	6
-- select MAX(LEN(RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),17)+LEFT(MONEDA,3)))
FROM POZCON_CLIENTI
--JOIN PROPRIETATI ON proprietati.Tip='NOMENCL' AND proprietati.Cod_proprietate='GRUPAVANZARE' 
--	AND proprietati.Valoare=POZCON_CLIENTI.VALOARE_ATRIBUT_PRODUS
--LEFT JOIN NOMENCL ON NOMENCL.Cod=proprietati.Cod 
--	AND (NOMENCL.Furnizor=POZCON_CLIENTI.BRAND OR NOMENCL.Furnizor=POZCON_CLIENTI.codfiscal_BRAND)
	
DELETE POZCON
WHERE TIP='BF'	

INSERT POZCON
SELECT * FROM POZCON_CLIENTIDX



select top 0 *
into POZCON_CLIENTI_TERTI
FROM TERTI

TRUNCATE TABLE POZCON_CLIENTI_TERTI
INSERT POZCON_CLIENTI_TERTI
SELECT DISTINCT --*,
'1' --Subunitate	char	no	9
,ISNULL(NULLIF(RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),13),''),'')  --Tert	char	no	13
,LEFT(CLIENT,80) --Denumire	char	no	80
,ISNULL(NULLIF(RIGHT(REPLACE(REPLACE(RTRIM(cod_fiscal),' ',''),'.',''),16),''),'') --Cod_fiscal	char	no	16
,'' --Localitate	char	no	35
,'' --Judet	char	no	20
,'' --Adresa	char	no	60
,'' --Telefon_fax	char	no	20
,'' --Banca	char	no	20
,'' --Cont_in_banca	char	no	35
,0 --Tert_extern	bit	no	1
,''--LEFT(ISNULL((SELECT MAX(G.GRUPA) FROM gterti G WHERE G.Denumire=CON_CLIENTI.SIC_CODE),CON_CLIENTI.SIC_CODE),3) --Grupa	char	no	3
,'401.2'--Cont_ca_furnizor	char	no	13	     
,'411.1'--Cont_ca_beneficiar	char	no	13	  
,0--Sold_ca_furnizor	float	no	8	53   
,0--Sold_ca_beneficiar	float	no	8	53   
,0--CASE ISNUMERIC( [limita credit]) WHEN 1 THEN CONVERT(INT, [limita credit]) ELSE 0 END --Sold_maxim_ca_beneficiar	float	no	8	53   
,0--Disccount_acordat	real	no	4	24  
-- SELECT * 
FROM POZCON_CLIENTI
where cod_fiscal NOT IN ('','0')

INSERT TERTI
SELECT * FROM POZCON_CLIENTI_TERTI
WHERE TERT NOT IN (SELECT TERT FROM TERTI)

select * from pozcon where Contract like 'RO1317%'

select * from con where Contract like 'RO1317%'

	SELECT BRAND, VALOARE_ATRIBUT_PRODUS
	INTO GRUPE_VANZARE_POZCON_CLIENTI
	FROM POZCON_CLIENTI
	GROUP BY  BRAND, VALOARE_ATRIBUT_PRODUS
	ORDER BY  BRAND, VALOARE_ATRIBUT_PRODUS

DROP TABLE GRUPE_VANZARE
SELECT DISTINCT GRUPA_VANZARE 
INTO GRUPE_VANZARE
FROM GRUPE_VANZARE_NOM_CATEG
UNION
SELECT DISTINCT VALOARE_ATRIBUT_PRODUS FROM GRUPE_VANZARE_POZCON_CLIENTI
ORDER BY 1

SELECT GRUPA_VANZARE
FROM GRUPE_VANZARE
GROUP BY GRUPA_VANZARE
HAVING COUNT(DISTINCT FURNIZOR)>1

SELECT ROW_NUMBER() OVER(PARTITION BY FURNIZOR ORDER BY FURNIZOR,GRUPA_VANZARE) 
,*FROM GRUPE_VANZARE
ORDER BY FURNIZOR,GRUPA_VANZARE

DROP TABLE FURNIZORI_GRUPE_VANZARE
SELECT DISTINCT ROW_NUMBER() OVER( ORDER BY FURNIZOR) AS IDFURNIZOR,   FURNIZOR
INTO FURNIZORI_GRUPE_VANZARE
FROM GRUPE_VANZARE
GROUP BY FURNIZOR
ORDER BY FURNIZOR

SELECT * FROM FURNIZORI_GRUPE_VANZARE

SELECT * FROM GRUPE_VANZARE

	SELECT VALOARE_ATRIBUT_PRODUS
	--INTO GRUPE_VANZARE_POZCON_CLIENTI
	FROM POZCON_CLIENTI
	GROUP BY VALOARE_ATRIBUT_PRODUS
	HAVING COUNT(DISTINCT BRAND)>1
	
	SELECT * FROM GRUPE_VANZARE_POZCON_CLIENTI
	
	SELECT * FROM GRUPE_VANZARE_NOM_CATEG
	WHERE GRUPA_VANZARE NOT IN (SELECT VALOARE_ATRIBUT_PRODUS FROM GRUPE_VANZARE_POZCON_CLIENTI)
	
	SELECT * FROM GRUPE_VANZARE_POZCON_CLIENTI
	WHERE VALOARE_ATRIBUT_PRODUS NOT IN (SELECT GRUPA_VANZARE FROM GRUPE_VANZARE_NOM_CATEG)
	
	SELECT * FROM POZCON_CLIENTI
	
	SELECT * FROM GRUPE_VANZARE