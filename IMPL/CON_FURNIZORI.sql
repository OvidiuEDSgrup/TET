SELECT TOP 0 * 
--INTO CON_FURNIZORIDX
FROM con

--INSERT CON_FURNIZORIDX
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

--INSERT TERTICONIDX
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

--INSERT TERTIDX
SELECT * FROM TERTICONIDX
WHERE TERT NOT IN (SELECT TERT FROM TERTIDX)

----TRUNCATE TABLE TERTI
--INSERT TERTI
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

--TRUNCATE TABLE POZCON_FURNIZORIDX
--INSERT POZCON_FURNIZORIDX
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

--DELETE con
WHERE TIP='FA'
--INSERT con
select * from CON_FURNIZORIDX

--DELETE pozcon
WHERE TIP='FA'
--INSERT pozcon
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

--TRUNCATE TABLE NOMENCLCONIDX
--INSERT NOMENCLCONIDX
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

--INSERT NOMENCLidx
SELECT *
FROM NOMENCLCONIDX
WHERE Cod NOT IN 
(SELECT Cod FROM nomenclidx)

--TRUNCATE TABLE nomencl
--INSERT nomencl
select * from NOMENCLidx

----DELETE pozcon where tert=''

SELECT * from pozcon_coduri_mari
select
p.Subunitate
,p.Tip
,p.Contract
,p.Tert
,p.Punct_livrare
,p.Data
,n.codnou
,p.Cantitate
,p.Pret
,p.Pret_promotional
,p.Discount
,p.Termen
,p.Factura
,p.Cant_disponibila
,p.Cant_aprobata
,p.Cant_realizata
,p.Valuta
,p.Cota_TVA
,p.Suma_TVA
,p.Mod_de_plata
,p.UM
,p.Zi_scadenta_din_luna
,p.Explicatii
,p.Numar_pozitie
,p.Utilizator
,p.Data_operarii
,p.Ora_operarii
from pozcon_coduri_mari p join nomencl_coduri_mari n on n.cod=p.Cod

SELECT * from pozcon_coduri_mari
where tert<>''
and cod not in (select n.cod from nomencl n) and LEN(cod)>20
--and cod not in (select n.cod from nomencl_coduri_mari n)
and tert not in (select tert from terti)

--INSERT pozcon
SELECT 
p.Subunitate
,p.Tip
,p.Contract
,p.Tert
,p.Punct_livrare
,p.Data
,n.codnou
,p.Cantitate
,p.Pret
,p.Pret_promotional
,p.Discount
,p.Termen
,p.Factura
,p.Cant_disponibila
,p.Cant_aprobata
,p.Cant_realizata
,p.Valuta
,p.Cota_TVA
,p.Suma_TVA
,p.Mod_de_plata
,p.UM
,p.Zi_scadenta_din_luna
,p.Explicatii
,p.Numar_pozitie
,p.Utilizator
,p.Data_operarii
,p.Ora_operarii
from pozcon_coduri_mari p join nomencl_coduri_mari n on p.Cod=n.cod
where tert<>''
and p.cod not in (select n.cod from nomencl n) and LEN(p.cod)>20

select DISTINCT VALUTA from CON_FURNIZORI

----UPDATE con
--set Loc_de_munca=''
--where tip in ('FA','BF')
--and con.Loc_de_munca not in (select cod from lm)

select (select MAX(p.valuta) from pozcon p where p.Subunitate='1' and p.Contract=con.Contract and p.Tert=con.Tert and p.tip=con.tip and p.Valuta<>con.Valuta) 
,* from con where exists 
(select 1 from pozcon p where p.Contract=con.Contract and p.Tert=con.Tert and p.Valuta<>con.Valuta) 
and con.Tip IN ('FA','BF')

select distinct contract from con



select * from pozcon p where rtrim(p.contract) like '%[^0-9]'

select * from pozcon where tert not in 
(select tert from terti)
and (tert in (select tert from terti_final_sters)
or tert in (select tert from terti_vechi_stersi))

select * from terti_final_sters ts where ts.Tert not in (select t.tert from terti t)
and (ts.Tert in (select p.tert from pozcon p)
or ts.Tert in (select p.tert from pozdoc p)
or ts.Tert in (select p.tert from facturi p)
or ts.Tert in (select p.tert from efecte p)
or ts.Tert in (select p.tert from con p)
or ts.Tert in (select p.furnizor from nomencl p)) 
and ts.Denumire not in (select t.denumire from terti t)

select * from terti_vechi_stersi ts where ts.Tert not in (select t.tert from terti t)
and (ts.Tert in (select p.tert from pozcon p)
or ts.Tert in (select p.tert from pozdoc p)
or ts.Tert in (select p.tert from facturi p)
or ts.Tert in (select p.tert from efecte p)
or ts.Tert in (select p.tert from con p)
or ts.Tert in (select p.furnizor from nomencl p)) 
and ts.Denumire not in (select t.denumire from terti t)

select t.tert,t1.Denumire,t2.Denumire from 
(select p.tert from pozcon p
union select p.tert from pozdoc p
union select p.tert from facturi p
union select p.tert from efecte p
union select p.furnizor from nomencl p) t left join terti_final_sters t1 on t1.tert=t.tert left join terti_vechi_stersi t2 on t2.tert=t.tert
where t.Tert not in (select t.tert from terti t)
and coalesce(t1.tert,t2.tert,'')<>''
and coalesce(t1.denumire,t2.denumire,'') in (select t.denumire from terti t)

select * from nomencl n
where n.Cont like '371_2%'

select distinct cont from nomencl n
where n.Cont not in (select c.cont from conturi c)

--UPDATE nomencl
set Cont='371.1'
where cont='371.2'

--UPDATE nomencl
set Cont='371.1'
where cont='380'

select * from nomencl n
where n.Cont not in (select c.cont from conturi c)

--INSERT terti
select * from terti_vechi_stersi t where 
t.Tert not in (select t1.Tert from terti t1)
and t.Denumire not in (select t1.Denumire from terti t1)
and t.Tert in 
(select t.tert from 
(select p.tert from pozcon p
union select p.tert from pozdoc p
union select p.tert from facturi p
union select p.tert from efecte p
union select p.furnizor from nomencl p) t left join terti_final_sters t1 on t1.tert=t.tert left join terti_vechi_stersi t2 on t2.tert=t.tert
where t.Tert not in (select t.tert from terti t)
and coalesce(t1.tert,t2.tert,'')<>'')

select DISTINCT CONTRACT,valuta from pozcon where exists 
(select 1 from con where con.Contract=pozcon.Contract and con.Tert=pozcon.Tert and con.Valuta like 'RO%')
AND Subunitate='1' 

select * from pozcon p where contract in 
(select contract from con where exists 
(select 1 from pozcon p where p.Contract=con.Contract and p.Tert=con.Tert and p.Valuta<>con.Valuta) 
and con.Tip IN ('FA','BF')) AND Subunitate='1'
order by tip,Contract,valuta

select p.tert,COUNT(distinct p.valuta) 
from pozcon p join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert
where p.Subunitate='1' and p.tip IN ('FA','BF')
group by p.tert
having COUNT(distinct p.valuta)=1 and MAX(p.valuta)<>MAX(c.valuta)

select * 
from con c
where c.Subunitate='1' and c.tip IN ('FA','BF')
and c.Valuta<>(select MAX(p.valuta) from pozcon p 
where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert 
group by p.Valuta having COUNT(distinct p.valuta)=1)

--UPDATE c
set Valuta=(select MAX(p.valuta) from pozcon p 
where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert 
group by p.Valuta having COUNT(distinct p.valuta)=1)
from con c
where c.Subunitate='1' and c.tip IN ('FA','BF')
and c.Valuta<>(select MAX(p.valuta) from pozcon p 
where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert 
group by p.Valuta having COUNT(distinct p.valuta)=1)

select 
(select distinct top 1  p.valuta from pozcon p 
where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert)
,*
from con c
where c.Subunitate='1' and c.tip IN ('FA','BF')
and c.Valuta not in (select distinct p.valuta from pozcon p 
where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert)
and exists (select distinct p.valuta from pozcon p 
where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert)

REPLACE((SELECT RTRIM(t.Explicatii)+' la '+LTRIM(RTRIM(CONVERT(CHAR,t.Termen,103)))+' ' AS [data()] FROM Termene t WHERE MAX(pozcon.Subunitate)=t.Subunitate AND MAX(pozcon.Tip)=t.Tip AND MAX(pozcon.Data)=t.Data and MAX(pozcon.Tert)=t.Tert and MAX(pozcon.Contract)=t.Contract and MAX(pozcon.Cod)=t.Cod ORDER BY t.Termen FOR XML PATH('')),'  ',' (+) ')

select t.tert as [data()] from terti t for xml path('')

select contract, COUNT(distinct valuta) 
from pozcon p where p.Subunitate='1' and p.tip IN ('FA','BF') 
and not exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert)
--and RIGHT(rtrim(contract),2)<>LEFT(p.valuta,2)
group by contract
having COUNT(distinct valuta)>1

select *
from pozcon p where p.Subunitate='1' and p.tip IN ('FA','BF') 
and RIGHT(rtrim(contract),2)<>LEFT(p.valuta,2)
and not exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert)
and exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=rtrim(p.Contract)+LEFT(p.valuta,2) and c.Tert=p.Tert)



select 
(select count(1) from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta=p.Valuta)
,*
from pozcon p where p.Subunitate='1' and p.tip IN ('FA','BF') 
--and RIGHT(rtrim(contract),2)<>LEFT(p.valuta,2)
and not exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert)
and exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta=p.Valuta)


select * from con where con.tert='RO14584341        '

select * from pozcon p where p.Tert<>LEFT(p.Contract,LEN(p.tert))

--UPDATE pozcon
set Contract=(select c.Contract from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta=p.Valuta)
from pozcon p where p.Subunitate='1' and p.tip IN ('FA','BF') 
--and RIGHT(rtrim(contract),2)<>LEFT(p.valuta,2)
and not exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert)
and exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta=p.Valuta)


select 
(select contract+'.'+valuta from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta<>p.Valuta)
,*
from pozcon p where p.Subunitate='1' and p.tip IN ('FA','BF') 
--and RIGHT(rtrim(contract),2)<>LEFT(p.valuta,2)
and not exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert)
and exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta<>p.Valuta)

----INSERT con
select 
c.Subunitate
, c.Tip
--, c.Contract
,rtrim(c.tert)+(select max(left(p.Valuta,2)) from pozcon p where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta<>p.Valuta and c.Contract<>p.Contract
	and not exists
	(select 1 from con c1 where c1.Subunitate=p.Subunitate and c1.Tip=p.Tip and c1.Contract=p.Contract and c1.Tert=p.Tert))
, c.Tert
, c.Punct_livrare
, c.Data
, c.Stare
, c.Loc_de_munca
, c.Gestiune
, c.Termen
, c.Scadenta
, c.Discount
--, c.Valuta
,(select max(p.Valuta) from pozcon p where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta<>p.Valuta and c.Contract<>p.Contract
	and not exists
	(select 1 from con c1 where c1.Subunitate=p.Subunitate and c1.Tip=p.Tip and c1.Contract=p.Contract and c1.Tert=p.Tert))
, c.Curs
, c.Mod_plata
, c.Mod_ambalare
, c.Factura
, c.Total_contractat
, c.Total_TVA
, c.Contract_coresp
, c.Mod_penalizare
, c.Procent_penalizare
, c.Procent_avans
, c.Avans
, c.Nr_rate
, c.Val_reziduala
, c.Sold_initial
, c.Cod_dobanda
, c.Dobanda
, c.Incasat
, c.Responsabil
, c.Responsabil_tert
, c.Explicatii
, c.Data_rezilierii
from con c 
where c.Subunitate='1' and c.tip IN ('FA','BF') 
and exists 
(select 1 from pozcon p where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta<>p.Valuta and c.Contract<>p.Contract
	and not exists
	(select 1 from con c1 where c1.Subunitate=p.Subunitate and c1.Tip=p.Tip and c1.Contract=p.Contract and c1.Tert=p.Tert))
	
	
	--select * from pozcon where pozcon.tert='RO14584341        '
	select * from con c where c.tert in 
	('RO25354216',        
'RO4144033')      
	select * from pozcon c where c.tert in 
	('RO25354216',        
'RO4144033') 

----INSERT con
select 
c.Subunitate
, c.Tip
--, c.Contract
,(select max(p.Contract) from pozcon p where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta<>p.Valuta and c.Contract<>p.Contract
	and not exists
	(select 1 from con c1 where c1.Subunitate=p.Subunitate and c1.Tip=p.Tip and c1.Contract=p.Contract and c1.Tert=p.Tert))
, c.Tert
, c.Punct_livrare
, c.Data
, c.Stare
, c.Loc_de_munca
, c.Gestiune
, c.Termen
, c.Scadenta
, c.Discount
--, c.Valuta
,(select max(p.Valuta) from pozcon p where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta<>p.Valuta and c.Contract<>p.Contract
	and not exists
	(select 1 from con c1 where c1.Subunitate=p.Subunitate and c1.Tip=p.Tip and c1.Contract=p.Contract and c1.Tert=p.Tert))
, c.Curs
, c.Mod_plata
, c.Mod_ambalare
, c.Factura
, c.Total_contractat
, c.Total_TVA
, c.Contract_coresp
, c.Mod_penalizare
, c.Procent_penalizare
, c.Procent_avans
, c.Avans
, c.Nr_rate
, c.Val_reziduala
, c.Sold_initial
, c.Cod_dobanda
, c.Dobanda
, c.Incasat
, c.Responsabil
, c.Responsabil_tert
, c.Explicatii
, c.Data_rezilierii
from con c 
where c.Subunitate='1' and c.tip IN ('FA','BF') 
and exists 
(select 1 from pozcon p where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Tert=p.Tert and c.Valuta<>p.Valuta and c.Contract<>p.Contract
	and not exists
	(select 1 from con c1 where c1.Subunitate=p.Subunitate and c1.Tip=p.Tip and c1.Contract=p.Contract and c1.Tert=p.Tert))
	
	----INSERT con
    select --*,
p.Subunitate	--Subunitate	char	9
,p.Tip	--Tip	char	2
,p.Contract	--Contract	char	20
,p.Tert	--Tert	char	13
,''	--Punct_livrare	char	13
,p.Data	--Data	datetime	8
,'1'	--Stare	char	1
,''	--Loc_de_munca	char	9
,'101'	--Gestiune	char	9
,p.Data	--Termen	datetime	8
,0	--Scadenta	smallint	2
,0	--Discount	real	4
,MAX(p.Valuta)	--Valuta	char	3
,0	--Curs	float	8
,''	--Mod_plata	char	1
,''	--Mod_ambalare	char	1
,''	--Factura	char	20
,0	--Total_contractat	float	8
,0	--Total_TVA	float	8
,''	--Contract_coresp	char	20
,''	--Mod_penalizare	char	13
,0	--Procent_penalizare	real	4
,0	--Procent_avans	real	4
,0	--Avans	float	8
,0	--Nr_rate	smallint	2
,0	--Val_reziduala	float	8
,0	--Sold_initial	float	8
,''	--Cod_dobanda	char	20
,0	--Dobanda	real	4
,0	--Incasat	float	8
,''	--Responsabil	char	20
,''	--Responsabil_tert	char	20
,''	--Explicatii	char	50
,''	--Data_rezilierii	datetime	8   
from pozcon p  where  p.Subunitate='1' and p.tip IN ('FA','BF') 
    and not exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert)
group by Subunitate, Tip, Data, Contract, Tert


select * 
from pozcon p  where  p.Subunitate='1' and p.tip IN ('FA','BF') 
    and exists 
(select 1 from con c where c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert and p.Valuta<>c.Valuta)

select * from pozcon p where p.Subunitate='1' and p.Tip='fa' and p.Cota_TVA<>24

select * from con p where p.Subunitate='1' and p.Tip='fa' and p.t<>24


SELECT TOP 0 *
--INTO POZCON_PRETURI_NETE_ACV
FROM POZCON

-- TRUNCATE TABLE POZCON_PRETURI_NETE_ACV INSERT POZCON_PRETURI_NETE_ACV
SELECT --*,
'1'	--Subunitate	char	9
,'FA'	--Tip	char	2
,'BE0464842608'	--Contract	char	20
,'BE0464842608' 	--Tert	char	13
,''	--Punct_livrare	char	13
,'2012-01-01'	--Data	datetime	8
,LEFT(p.Cod,8)	--Cod	char	20
,0	--Cantitate	float	8
,CONVERT(DECIMAL(17,5),REPLACE(p.[Fob net],',',''))	--Pret	float	8
,0	--Pret_promotional	float	8
,0	--Discount	real	4
,''	--Termen	datetime	8
,'101'	--Factura	char	20
,0	--Cant_disponibila	float	8
,0	--Cant_aprobata	float	8
,0	--Cant_realizata	float	8
,'EUR'	--Valuta	char	3
,24	--Cota_TVA	real	4
,0	--Suma_TVA	float	8
,''	--Mod_de_plata	char	8
,''	--UM	char	1
,0	--Zi_scadenta_din_luna	smallint	2
,''	--Explicatii	char	200
,0	--Numar_pozitie	int	4
,'IMPL'	--Utilizator	char	10
,GETDATE()	--Data_operarii	datetime	8
,''	--Ora_operarii	char	6
	-- SELECT *
FROM PRETURI_NETE_ACV1 P

select P.COD FROM POZCON_PRETURI_NETE_ACV P GROUP BY P.COD HAVING COUNT(*)>1

select fa.cod
-- update fa set fa.pret=pa.pret
from pozcon fa inner join POZCON_PRETURI_NETE_ACV pa on pa.Subunitate=fa.Subunitate and pa.Tip=fa.tip and pa.Contract=fa.Contract
and pa.Data=fa.Data and pa.Tert=fa.Tert and pa.Cod=fa.Cod
--where fa.Pret<>pa.Pret
--group by fa.cod
--having COUNT(*)>1

-- insert pozcon
select * FROM POZCON_PRETURI_NETE_ACV pa
where not exists 
(select 1 from pozcon fa where pa.Subunitate=fa.Subunitate and pa.Tip=fa.tip and pa.Contract=fa.Contract
and pa.Data=fa.Data and pa.Tert=fa.Tert and pa.Cod=fa.Cod )

SELECT TOP 0 *
INTO POZCON_PRETURI_NETE_HENCO
FROM POZCON

-- TRUNCATE TABLE POZCON_PRETURI_NETE_HENCO INSERT POZCON_PRETURI_NETE_HENCO
SELECT DISTINCT --*,
'1'	--Subunitate	char	9
,'FA'	--Tip	char	2
,LEFT(p.tert,20)	--Contract	char	20
,LEFT(p.tert,13) 	--Tert	char	13
,''	--Punct_livrare	char	13
,'2012-01-01'	--Data	datetime	8
,LEFT(p.Cod,20)	--Cod	char	20
,0	--Cantitate	float	8
,CONVERT(DECIMAL(17,5),REPLACE(p.[Fob net],',',''))	--Pret	float	8
,0	--Pret_promotional	float	8
,0	--Discount	real	4
,''	--Termen	datetime	8
,'101'	--Factura	char	20
,0	--Cant_disponibila	float	8
,0	--Cant_aprobata	float	8
,0	--Cant_realizata	float	8
,'EUR'	--Valuta	char	3
,24	--Cota_TVA	real	4
,0	--Suma_TVA	float	8
,''	--Mod_de_plata	char	8
,''	--UM	char	1
,0	--Zi_scadenta_din_luna	smallint	2
,''	--Explicatii	char	200
,0	--Numar_pozitie	int	4
,'IMPL'	--Utilizator	char	10
,GETDATE()	--Data_operarii	datetime	8
,''	--Ora_operarii	char	6
	-- SELECT *
FROM PRETURI_NETE_HENCO P
--where p.cod='UFH-ESK060303-M     '

select P.COD FROM POZCON_PRETURI_NETE_HENCO P GROUP BY P.COD HAVING COUNT(*)>1

select fa.cod
-- update fa set fa.pret=pa.pret
from pozcon fa inner join POZCON_PRETURI_NETE_HENCO pa on pa.Subunitate=fa.Subunitate and pa.Tip=fa.tip and pa.Contract=fa.Contract
and pa.Data=fa.Data and pa.Tert=fa.Tert and pa.Cod=fa.Cod
--where fa.Pret<>pa.Pret
--group by fa.cod having COUNT(*)>1

-- insert pozcon
select * FROM POZCON_PRETURI_NETE_HENCO pa
where not exists 
(select 1 from pozcon fa where pa.Subunitate=fa.Subunitate and pa.Tip=fa.tip and pa.Contract=fa.Contract
and pa.Data=fa.Data and pa.Tert=fa.Tert and pa.Cod=fa.Cod )

SELECT TOP 0 *
INTO NOMENCL_PRETURI_NETE_HENCO
FROM NOMENCL

-- TRUNCATE TABLE NOMENCL_PRETURI_NETE_HENCO INSERT NOMENCL_PRETURI_NETE_HENCO
SELECT
LEFT(P.Cod,20)	--Cod	char	no	30
,'M'	--Tip	char	no	1
,LEFT(P.[Denumirea produsului],150)	--Denumire	char	no	150
,LEFT(P.UM,3)	--UM	char	no	3
,'' --UM_1	char	no	3
,''	--Coeficient_conversie_1	float	no	8
,''	--UM_2	char	no	20
,0	--Coeficient_conversie_2	float	no	8
,'371.1'	--Cont	char	no	13
,''	--Grupa	char	no	13
,LEFT('EUR',3)	--Valuta	char	no	3
,P.[Fob net]	--Pret_in_valuta	float	no	8
,0	--Pret_stoc	float	no	8
,0	--Pret_vanzare	float	no	8
,0	--Pret_cu_amanuntul	float	no	8
,24	--Cota_TVA	real	no	4
,0	--Stoc_limita	float	no	8
,0	--Stoc	float	no	8
,0	--Greutate_specifica	float	no	8
,RIGHT(REPLACE(REPLACE(RTRIM(P.TERT),' ',''),'.',''),13)	--Furnizor	char	no	13
,''	--Loc_de_munca	char	no	150
,''	--Gestiune	char	no	13
,''	--Categorie	smallint	no	2
,''	--Tip_echipament	char	no	21
--select *
FROM PRETURI_NETE_HENCO P

--insert nomencl
select * from NOMENCL_PRETURI_NETE_HENCO n where n.cod not in 
(select nm.cod from nomencl nm)

SELECT TOP 0 *
INTO NOMENCL_PRETURI_NETE_ACV
FROM NOMENCL

-- TRUNCATE TABLE NOMENCL_PRETURI_NETE_ACV INSERT NOMENCL_PRETURI_NETE_ACV
SELECT
LEFT(P.Cod,20)	--Cod	char	no	30
,'M'	--Tip	char	no	1
,LEFT(P.[Denumirea produsului],150)	--Denumire	char	no	150
,LEFT(P.UM,3)	--UM	char	no	3
,'' --UM_1	char	no	3
,''	--Coeficient_conversie_1	float	no	8
,''	--UM_2	char	no	20
,0	--Coeficient_conversie_2	float	no	8
,'371.1'	--Cont	char	no	13
,''	--Grupa	char	no	13
,LEFT('EUR',3)	--Valuta	char	no	3
,P.[Fob net]	--Pret_in_valuta	float	no	8
,0	--Pret_stoc	float	no	8
,0	--Pret_vanzare	float	no	8
,0	--Pret_cu_amanuntul	float	no	8
,24	--Cota_TVA	real	no	4
,0	--Stoc_limita	float	no	8
,0	--Stoc	float	no	8
,0	--Greutate_specifica	float	no	8
,RIGHT(REPLACE(REPLACE(RTRIM('BE0464842608'),' ',''),'.',''),13)	--Furnizor	char	no	13
,''	--Loc_de_munca	char	no	150
,''	--Gestiune	char	no	13
,''	--Categorie	smallint	no	2
,''	--Tip_echipament	char	no	21
--select *
FROM PRETURI_NETE_ACV1 P

--insert nomencl
select * from NOMENCL_PRETURI_NETE_ACV n where n.cod not in 
(select nm.cod from nomencl nm)
