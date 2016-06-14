select --TOP 0 
* 
--into EFECTE_INCASAT_CEC_ASIS
from efimpl

--INSERT terti
select * from terti_final_sters
where tert not in (select tert from terti)

--UPDATE CEC_DEINCASAT
set CUSTOMER_NAME='COMPUTER NETWORK SOLUTIONS SRL'

--TRUNCATE table EFECTE_INCASAT_CEC_ASIS
--INSERT EFECTE_INCASAT_CEC_ASIS
SELECT --*,
'1'	--Subunitate	char	9
,'I'	--Tip	char	1
,(SELECT TOP 1 ISNULL(f.TERT,t.tert) FROM TERTI T LEFT JOIN (select tert from factimpl where Cont_de_tert='401.1' group by tert) f on t.Tert=f.Tert 
	WHERE T.Denumire LIKE C.CUSTOMER_NAME ORDER BY ISNULL(f.tert,0) DESC )	--Tert	char	13
,SUBSTRING(c.RECEIPT_NUMBER,CHARINDEX(' ',c.RECEIPT_NUMBER)+1,8)	--Nr_efect	char	8
,'413'	--Cont	char	13
,LEFT(C.[data inreg in contabilitate],10)	--Data	datetime	8
,LEFT(C.[scadenta CEC   BO],10)	--Data_scadentei	datetime	8
,CONVERT(FLOAT,REPLACE(C.[valoare CEC   BO],',',''))	--Valoare	float	8
,''	--Valuta	char	3
,0	--Curs	float	8
,0	--Valoare_valuta	float	8
,0	--Decontat	float
,CONVERT(FLOAT,REPLACE(C.[valoare CEC   BO],',',''))	--Sold	float	8
,0	--Decontat_valuta	float	8
,0	--Sold_valuta	float	8
,''	--Loc_de_munca	char	9
,''	--Comanda	char	40
,''	--Data_decontarii	datetime	8
,''	--Explicatii	char	30
	--select * 
from CEC_DEINCASAT C
WHERE C.CUSTOMER_NAME<>'' 
--AND NOT EXISTS (SELECT TOP 1 ISNULL(f.TERT,t.tert) FROM TERTI T LEFT JOIN (select tert from factimpl group by tert) f on t.Tert=f.Tert WHERE T.Denumire LIKE C.CUSTOMER_NAME ORDER BY ISNULL(f.tert,0) DESC )
--GROUP BY C.CUSTOMER_NAME

--UPDATE CEC_DEINCASAT
SET CUSTOMER_NAME='RAMIVALD INSTAL SRL'
WHERE CUSTOMER_NAME='RAMIVLAD INSTAL SRL'

--UPDATE CEC_DEINCASAT
SET CUSTOMER_NAME='SAM INSTAL SRL'
WHERE CUSTOMER_NAME='SAMINSTAL SRL'


SELECT T.Tert,T.Denumire, C.* FROM CEC_DEINCASAT C 
JOIN TERTI T ON T.Denumire LIKE C.CUSTOMER_NAME
WHERE ISNULL((SELECT COUNT(*) FROM TERTI T LEFT JOIN (select tert from factimpl group by tert) f on t.Tert=f.Tert WHERE f.Tert is null OR T.Denumire LIKE C.CUSTOMER_NAME),0)>=2
ORDER BY C.CUSTOMER_NAME

select * from terti_vechi_stersi where Denumire like '%ramivlad%' or Denumire like '%saminstal%'

--TRUNCATE table efimpl
--INSERT efimpl
select * from EFECTE_INCASAT_CEC_ASIS

select e.Tert,e.Nr_efect
from EFECTE_INCASAT_CEC_ASIS e
group by e.Tert,e.Nr_efect
having COUNT(*)>1

select (select SUM(e.Sold) from efimpl e where e.Tert=f.Tert), * from factimpl f where f.Tert in 
(select e.tert from efimpl e)

--TRUNCATE table factimpl
--INSERT  factimpl
select * from factimpl_copie1

select f.tert,f.factura,f.tip
from factimpl_copie1 f
group by f.tert,f.factura,f.tip
having COUNT(*)>1

select * from factimpl_copie1 f
where f.Tert in 
(select f.tert
from factimpl_copie1 f
group by f.tert,f.factura,f.tip
having COUNT(*)>1) order by tert


--UPDATE factimpl
SET Valoare =valoare- (select SUM(e.Sold) from efimpl e where e.Tert=f.Tert)
,Sold=sold-(select SUM(e.Sold) from efimpl e where e.Tert=f.Tert)
from factimpl f where f.Cont_de_tert='411.1' AND f.Tert in 
(select e.tert from efimpl e)

select * from efimpl e where e.tert not in 
(select f.tert from factimpl f)

select * from NOM_CATEG

select e.*,f.* from
(select e.tert,SUM(sold) sold,COUNT(*) as nr,min(e.Cont) cont  from efecte e 
group by e.tert ) e left join
(select f.tert,SUM(f.Sold) sold,COUNT(*) as nr,min(f.cont_de_tert) cont 
from factimpl_copie1 f where f.Tert in 
(select e.tert from efimpl e)
group by f.tert) f on f.tert=e.tert
where e.sold>f.sold


select * from efimpl e where e.Tert='RO10026350   '

select * from factimpl_copie1 e where e.Tert='RO10026350   '