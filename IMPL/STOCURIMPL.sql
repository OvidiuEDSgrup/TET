select * 
--into STOCURIMPL_ISTORIC
from test..istoricstocuri

--TRUNCATE TABLE STOCURIMPL_ISTORIC
--INSERT STOCURIMPL_ISTORIC
SELECT --*,
'1'	--Subunitate	char	9
,'2011-12-31'	--Data_lunii	datetime	8
,MAX(G.Tip_gestiune	)--Tip_gestiune	char	1
,LEFT(C.gest,20)	--Cod_gestiune	char	20
,LEFT(Cod,30)	--Cod	char	30
,'2012-01-01'	--Data	datetime	8
,'IMPL'+LTRIM(CONVERT(CHAR,ROW_NUMBER() OVER( PARTITION BY C.gest,COD ORDER BY C.gest,COD,PRET)))	--Cod_intrare	char	30
,CONVERT(FLOAT,REPLACE(PRET,',',''))	--Pret	float	8
,0	--TVA_neexigibil	real	4
,0	--Pret_cu_amanuntul	float	8
,SUM(CONVERT(FLOAT,Scriptic))	--Stoc	float	8
,'371.1'	--Cont	char	13
,''	--Locatie	char	30
,'2012-01-01'	--Data_expirarii	datetime	8
,0	--Pret_vanzare	float	8
,''	--Loc_de_munca	char	9
,''	--Comanda	char	40
,''	--Contract	char	20
,''	--Furnizor	char	13
,''	--Lot	char	20
,0	--Stoc_UM2	float	8
,0	--Val1	float	8
,''	--Alfa1	char	30
,''	--Data1	datetime	8
	-- SELECT DISTINCT CONT
FROM STOCURIMPL S 
JOIN CONTGESTSTOCURIMPL C ON S.cont=C.CONT
JOIN gestiuni G ON G.Cod_gestiune=C.gest
where len(rtrim(s.Cod)) <=20
GROUP BY C.gest,Cod,PRET

select * from CONTGESTSTOCURIMPL

--UPDATE CONTGESTSTOCURIMPL
SET CONT_ASIS=LEFT(CONT,13)
	
--TRUNCATE TABLE istoricstocuri
--INSERT istoricstocuri
select * from  STOCURIMPL_ISTORIC

select * from istoricstocuri_coduri_mari

cont 	gest	denumire
3711	101	Marfuri
3711	101	Piese de schimb
3713	103	Dezmiembrari
3714	104	Marfa greu vandabila
3715	105	Promotionale Marketing
3716	106	Marfa Sala de curs
3717	107	Marfa AGV
3718	108	Marfuri neclare
3719	109	Marfuri defecte
 	 	 
 	 	 
371211	211	Magazin NT
371212	212	Magazin CJ

select * from nomencl 
where LEN(cod)>20
and cod in (select cod from stocuri)


select * 
from CONTGESTSTOCURIMPL where ASCII(cont)<>160

--UPDATE istoricstocuri
SET Cont='371.1'


select * 
into istoricstocuri_coduri_mari
where LEN(cod)>20

--DELETE istoricstocuri
from istoricstocuri
where LEN(cod)>20

select * from istoricstocuri
where cod not in (select cod from nomencl)

select TOP 0 *
into STOCURIMPL_CODURI_LIPSA
FROM NOMENCL

--TRUNCATE TABLE STOCURIMPL_CODURI_LIPSA
--INSERT STOCURIMPL_CODURI_LIPSA
SELECT --*,
LEFT(Cod,30)	--Cod	char	30
,'M'	--Tip	char	1
,LEFT(MAX(S.Denumire),150)	--Denumire	char	150
,LEFT(MAX(S.[U M ]),3)	--UM	char	3
,''	--UM_1	char	3
,0	--Coeficient_conversie_1	float	8
,''	--UM_2	char	20
,0	--Coeficient_conversie_2	float	8
,LEFT('371.1',13)	--Cont	char	13
,''	--Grupa	char	13
,''	--Valuta	char	3
,0	--Pret_in_valuta	float	8
,CONVERT(FLOAT,REPLACE(MAX(PRET),',',''))	--Pret_stoc	float	8
,CONVERT(FLOAT,REPLACE(MAX(PRET),',',''))	--Pret_vanzare	float	8
,CONVERT(FLOAT,REPLACE(MAX(PRET),',',''))	--Pret_cu_amanuntul	float	8
,'24'	--Cota_TVA	real	4
,0	--Stoc_limita	float	8
,0	--Stoc	float	8
,0	--Greutate_specifica	float	8
,''	--Furnizor	char	13
,''	--Loc_de_munca	char	150
,LEFT(MAX(C.gest),20)	--Gestiune	char	13
,''	--Categorie	smallint	2
,''	--Tip_echipament	char	21
		-- SELECT *
FROM STOCURIMPL S 
JOIN CONTGESTSTOCURIMPL C ON S.cont=C.CONT
JOIN gestiuni G ON G.Cod_gestiune=C.gest
--where len(rtrim(s.Cod)) <=20
GROUP BY Cod

--INSERT nomencl
SELECT * FROM STOCURIMPL_CODURI_LIPSA
WHERE COD NOT IN (SELECT COD FROM NOMENCL)
AND LEN(COD)<=20


--INSERT nomencl_coduri_mari
SELECT *,'' FROM STOCURIMPL_CODURI_LIPSA
WHERE COD NOT IN (SELECT COD FROM nomencl_coduri_mari)
and COD NOT IN (SELECT COD FROM nomencl)
AND LEN(COD)>20

--INSERT istoricstocuri
SELECT 
i.Subunitate
,i.Data_lunii
,i.Tip_gestiune
,i.Cod_gestiune
,n.codnou
,i.Data
,i.Cod_intrare
,i.Pret
,i.TVA_neexigibil
,i.Pret_cu_amanuntul
,i.Stoc
,i.Cont
,i.Locatie
,i.Data_expirarii
,i.Pret_vanzare
,i.Loc_de_munca
,i.Comanda
,i.Contract
,i.Furnizor
,i.Lot
,i.Stoc_UM2
,i.Val1
,i.Alfa1
,i.Data1
from istoricstocuri_coduri_mari i join nomencl_coduri_mari n on n.cod=i.Cod

select * from istoricstocuri_coduri_mari
select * from STOCURIMPL_CODURI_LIPSA 
WHERE COD LIKE 'BV 453_45gr/1/4"mx1/4"fm%'

select cod 
from nomencl n
group by cod
having COUNT(*)>1

select * from nomencl_coduri_mari n
where  n.cod in
(select cod from STOCURIMPL_CODURI_LIPSA)
and codnou=''

----DELETE nomencl_coduri_mari
-- from nomencl_coduri_mari n
--where  n.cod in
--(select cod from STOCURIMPL_CODURI_LIPSA)
--and codnou=''

select TOP 0 * 
into STOC_MAG_NT_ISTORIC
from test..istoricstocuri

SET DATEFORMAT DMY

--TRUNCATE TABLE STOC_MAG_NT_ISTORIC
--INSERT STOC_MAG_NT_ISTORIC
SELECT --TOP 2 --*,
'1'	--Subunitate	char	9
,convert(date,'2011-12-31')	--Data_lunii	datetime	8
,MAX(G.Tip_gestiune	)--Tip_gestiune	char	1
,LEFT('211',20)	--Cod_gestiune	char	20
,LEFT(s.cod,30)	--Cod	char	30
--,s.data_intrare	--Data	datetime	8
,CONVERT(DATETIME,s.data_intrare)	--Data	datetime	8
,'IMPL'+LTRIM(CONVERT(CHAR,ROW_NUMBER() OVER( PARTITION BY g.cod_gestiune,s.COD ORDER BY g.cod_gestiune,s.COD,CONVERT(DATETIME,s.data_intrare))))	--Cod_intrare	char	30
,CONVERT(FLOAT,REPLACE(s.[pret_intrare fara TVA],',',''))	--Pret	float	8
,max(s.tva)	--TVA_neexigibil	real	4
,s.[pret_vanzare_cu TVA ]	--Pret_cu_amanuntul	float	8
,SUM(CONVERT(FLOAT,s.cantitate))	--Stoc	float	8
,'371.1'	--Cont	char	13
,''	--Locatie	char	30
--,s.data_intrare	--Data_expirarii	datetime	8
,CONVERT(DATETIME,s.data_intrare)	--Data_expirarii	datetime	8
,s.[pret_vanzare fara TVA]	--Pret_vanzare	float	8
,''	--Loc_de_munca	char	9
,''	--Comanda	char	40
,''	--Contract	char	20
,''	--Furnizor	char	13
,''	--Lot	char	20
,0	--Stoc_UM2	float	8
,0	--Val1	float	8
,''	--Alfa1	char	30
,''	--Data1	datetime	8
	-- SELECT *
FROM STOC_MAG_NT S 
--JOIN CONTGESTSTOCURIMPL C ON S.cont=C.CONT
JOIN gestiuni G ON G.Cod_gestiune='211'
where len(rtrim(s.Cod)) <=20
GROUP BY g.cod_gestiune,Cod,s.[pret_intrare fara TVA],s.[pret_vanzare fara TVA],s.[pret_vanzare_cu TVA ],s.data_intrare

select * from stocuri

SELECT * FROM STOC_MAG_NT S where ISDATE(S.data_intrare)=1
WHERE left(S.data_intrare,2)>31
right(left(S.data_intrare,5),2)>12 

--UPDATE STOC_MAG_NT
SET data_intrare='30.12.2000'
where data_intrare='30.12.1899'

select * from STOC_MAG_NT_ISTORIC s
where s.Cod not in (select n.cod from nomencl n)

select TOP 0 *
into STOC_MAG_NT_CODURI_LIPSA
FROM NOMENCL

--TRUNCATE TABLE STOC_MAG_NT_CODURI_LIPSA
--INSERT STOC_MAG_NT_CODURI_LIPSA
SELECT --*,
LEFT(Cod,30)	--Cod	char	30
,'M'	--Tip	char	1
,LEFT(MAX(S.Denumire),150)	--Denumire	char	150
,LEFT(MAX(S.um),3)	--UM	char	3
,''	--UM_1	char	3
,0	--Coeficient_conversie_1	float	8
,''	--UM_2	char	20
,0	--Coeficient_conversie_2	float	8
,LEFT('371.1',13)	--Cont	char	13
,''	--Grupa	char	13
,''	--Valuta	char	3
,0	--Pret_in_valuta	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[pret_intrare fara TVA]),',',''))	--Pret_stoc	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[pret_vanzare fara TVA]),',',''))	--Pret_vanzare	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[pret_vanzare_cu TVA ]),',',''))	--Pret_cu_amanuntul	float	8
,max(s.tva)	--Cota_TVA	real	4
,0	--Stoc_limita	float	8
,0	--Stoc	float	8
,0	--Greutate_specifica	float	8
,''	--Furnizor	char	13
,''	--Loc_de_munca	char	150
,LEFT(MAX('211'),20)	--Gestiune	char	13
,'4'	--Categorie	smallint	2
,''	--Tip_echipament	char	21
		-- SELECT *
FROM STOC_MAG_NT S 
--JOIN CONTGESTSTOCURIMPL C ON S.cont=C.CONT
JOIN gestiuni G ON G.Cod_gestiune='211'
where len(rtrim(s.Cod)) <=20
GROUP BY s.Cod --,s.[pret_intrare fara TVA],s.[pret_vanzare fara TVA],s.[pret_vanzare_cu TVA ],s.data_intrare

--INSERT istoricstocuri
select * from STOC_MAG_NT_ISTORIC s

--INSERT nomencl
select * from STOC_MAG_NT_CODURI_LIPSA s
where s.Cod not in (select n.cod from nomencl n)


select TOP 0 * 
into STOC_MAG_CJ_ISTORIC
from test..istoricstocuri
alter table STOC_MAG_CJ_ISTORIC alter column cod char(30) not null

SET DATEFORMAT DMY

--TRUNCATE TABLE STOC_MAG_CJ_ISTORIC
--INSERT STOC_MAG_CJ_ISTORIC
SELECT --TOP 2 --*,
'1'	--Subunitate	char	9
,convert(date,'2011-12-31')	--Data_lunii	datetime	8
,MAX(G.Tip_gestiune	)--Tip_gestiune	char	1
,LEFT('212',20)	--Cod_gestiune	char	20
,LEFT(s.cod,30)	--Cod	char	30
--,s.data_intrare	--Data	datetime	8
,CONVERT(DATETIME,s.data_intrare)	--Data	datetime	8
,'IMPL'+LTRIM(CONVERT(CHAR,ROW_NUMBER() OVER( PARTITION BY g.cod_gestiune,s.COD ORDER BY g.cod_gestiune,s.COD,CONVERT(DATETIME,s.data_intrare))))	--Cod_intrare	char	30
,CONVERT(FLOAT,REPLACE(s.[pret_intrare fara TVA],',',''))	--Pret	float	8
,max(s.tva)	--TVA_neexigibil	real	4
,s.[pret_vanzare_cu TVA ]	--Pret_cu_amanuntul	float	8
,SUM(CONVERT(FLOAT,s.cantitate))	--Stoc	float	8
,'371.1'	--Cont	char	13
,''	--Locatie	char	30
--,s.data_intrare	--Data_expirarii	datetime	8
,CONVERT(DATETIME,s.data_intrare)	--Data_expirarii	datetime	8
,s.[pret_vanzare fara TVA]	--Pret_vanzare	float	8
,''	--Loc_de_munca	char	9
,''	--Comanda	char	40
,''	--Contract	char	20
,''	--Furnizor	char	13
,''	--Lot	char	20
,0	--Stoc_UM2	float	8
,0	--Val1	float	8
,''	--Alfa1	char	30
,''	--Data1	datetime	8
	-- SELECT max(len(cod))
FROM STOC_MAG_CJ S 
--JOIN CONTGESTSTOCURIMPL C ON S.cont=C.CONT
JOIN gestiuni G ON G.Cod_gestiune='212'
--where len(rtrim(s.Cod)) <=20
GROUP BY g.cod_gestiune,Cod,s.[pret_intrare fara TVA],s.[pret_vanzare fara TVA],s.[pret_vanzare_cu TVA ],s.data_intrare

-- SELECT *
--FROM STOC_MAG_CJ S 
--where len(cod)>20
--and cod in (select cod from nomencl_coduri_mari)

--UPDATE STOC_MAG_CJ_ISTORIC
SET cod=codnou
from STOC_MAG_CJ_ISTORIC s join nomencl_coduri_mari n on n.cod=s.cod

select * from STOC_MAG_CJ_ISTORIC s
where s.Cod not in (select n.cod from nomencl n)

select TOP 0 *
into STOC_MAG_CJ_CODURI_LIPSA
FROM NOMENCL
ALTER TABLE STOC_MAG_CJ_CODURI_LIPSA ALTER COLUMN COD CHAR(30) NOT NULL

--TRUNCATE TABLE STOC_MAG_CJ_CODURI_LIPSA
--INSERT STOC_MAG_CJ_CODURI_LIPSA
SELECT --*,
LEFT(Cod,30)	--Cod	char	30
,'M'	--Tip	char	1
,LEFT(MAX(S.Denumire),150)	--Denumire	char	150
,LEFT(MAX(S.um),3)	--UM	char	3
,''	--UM_1	char	3
,0	--Coeficient_conversie_1	float	8
,''	--UM_2	char	20
,0	--Coeficient_conversie_2	float	8
,LEFT('371.1',13)	--Cont	char	13
,''	--Grupa	char	13
,''	--Valuta	char	3
,0	--Pret_in_valuta	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[pret_intrare fara TVA]),',',''))	--Pret_stoc	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[pret_vanzare fara TVA]),',',''))	--Pret_vanzare	float	8
,CONVERT(FLOAT,REPLACE(MAX(s.[pret_vanzare_cu TVA ]),',',''))	--Pret_cu_amanuntul	float	8
,max(s.tva)	--Cota_TVA	real	4
,0	--Stoc_limita	float	8
,0	--Stoc	float	8
,0	--Greutate_specifica	float	8
,''	--Furnizor	char	13
,CASE WHEN len(rtrim(s.Cod))>20	THEN LEFT(s.Cod,30) ELSE '' END --Loc_de_munca	char	150
,LEFT(MAX('212'),20)	--Gestiune	char	13
,'4'	--Categorie	smallint	2
,''	--Tip_echipament	char	21
		-- SELECT *
FROM STOC_MAG_CJ S 
--JOIN CONTGESTSTOCURIMPL C ON S.cont=C.CONT
JOIN gestiuni G ON G.Cod_gestiune='212'
--where len(rtrim(s.Cod)) <=20
GROUP BY s.Cod --,s.[pret_intrare fara TVA],s.[pret_vanzare fara TVA],s.[pret_vanzare_cu TVA ],s.data_intrare

----INSERT nomencl
SELECT * FROM STOC_MAG_CJ_CODURI_LIPSA S
WHERE s.Cod not in (select n.cod from nomencl n)

--UPDATE STOC_MAG_CJ_CODURI_LIPSA 
SET cod=codnou
from STOC_MAG_CJ_CODURI_LIPSA s join nomencl_coduri_mari n on n.cod=s.cod

select * from nomencl where tip<>'P' AND denumire like 'Pach%'
--UPDATE nomencl
SET Tip='P'
where tip<>'P' AND denumire like 'Pach%'


--INSERT istoricstocuri
select * from STOC_MAG_CJ_ISTORIC

select sum(s.Stoc*s.Pret) from STOC_MAG_CJ_ISTORIC s
select sum(s.Stoc*s.Pret) from istoricstocuri s where s.Cod_gestiune='212'

select sum(s.Stoc*s.Pret) from STOC_MAG_NT_ISTORIC s
select sum(s.Stoc*s.Pret) from istoricstocuri s where s.Cod_gestiune='211'
SELECT * from istoricstocuri i where i.Cod='DO0021'
select * from stocuri s where s.Cod='DO0021'

select * 
--into STOCURI_CORECTATE_ISTORIC
from test..istoricstocuri

-- TRUNCATE TABLE STOCURI_CORECTATE_ISTORIC INSERT STOCURI_CORECTATE_ISTORIC
SELECT --*,
'1'	--Subunitate	char	9
,'2011-12-31'	--Data_lunii	datetime	8
,MAX(G.Tip_gestiune	)--Tip_gestiune	char	1
,LEFT(s.gest,20)	--Cod_gestiune	char	20
,LEFT(s.Cod,30)	--Cod	char	30
,'2012-01-01'	--Data	datetime	8
,coalesce((select top 1 i.Cod_intrare from  istoricstocuri i where i.Subunitate='1' and i.Cod_gestiune=LEFT(s.gest,20) and i.Cod=LEFT(s.Cod,30) and i.Pret=CONVERT(FLOAT,REPLACE(s.PRET,',','')))
,case ROW_NUMBER() OVER( PARTITION BY s.gest,s.COD ORDER BY s.gest,s.COD,CONVERT(FLOAT,REPLACE(s.PRET,',','')))
when 1 then (select min(i.Cod_intrare) from  istoricstocuri i where i.Subunitate='1' and i.Cod_gestiune=LEFT(s.gest,20) and i.Cod=LEFT(s.Cod,30))
else null end, 'IMPL'+LTRIM(CONVERT(CHAR,10+ROW_NUMBER() OVER( PARTITION BY s.gest,s.COD ORDER BY s.gest,s.COD,CONVERT(FLOAT,REPLACE(s.PRET,',',''))))))	--Cod_intrare	char	30
,CONVERT(FLOAT,REPLACE(s.PRET,',',''))	--Pret	float	8
,0	--TVA_neexigibil	real	4
,0	--Pret_cu_amanuntul	float	8
,SUM(CONVERT(FLOAT,s.Cantitati))	--Stoc	float	8
,'371.1'	--Cont	char	13
,''	--Locatie	char	30
,'2012-01-01'	--Data_expirarii	datetime	8
,0	--Pret_vanzare	float	8
,''	--Loc_de_munca	char	9
,''	--Comanda	char	40
,''	--Contract	char	20
,''	--Furnizor	char	13
,''	--Lot	char	20
,0	--Stoc_UM2	float	8
,0	--Val1	float	8
,''	--Alfa1	char	30
,''	--Data1	datetime	8
	-- SELECT *
FROM STOCURI_CORECTATE S 
JOIN gestiuni G ON G.Cod_gestiune=s.gest
--left join istoricstocuri i on i.Subunitate='1' and i.Cod_gestiune=LEFT(s.gest,20) and i.Cod=LEFT(s.Cod,30) and i.Pret=CONVERT(FLOAT,s.Cantitati)
--JOIN CONTGESTSTOCURIMPL C ON S.cont=C.CONT
--where len(rtrim(s.Cod)) <=20
GROUP BY s.gest,s.Cod,CONVERT(FLOAT,REPLACE(S.PRET,',',''))

select * from STOCURI_CORECTATE
select * from nomencl_coduri_mari where cod='BV 453_45gr/1/4"mx1/4"fm'
--update STOCURI_CORECTATE
--set Cod=codnou
--from STOCURI_CORECTATE s join nomencl_coduri_mari n on s.Cod=n.cod

select sum(s.Stoc*s.Pret) from istoricstocuri s where s.Cod_gestiune not in ('211','212')
select  sum(s.Stoc*s.Pret) from STOCURI_CORECTATE_ISTORIC s

select n.denumire, (s.Stoc-i.stoc) as dif_cant, i.Stoc as stoc_initial,s.stoc as stoc_corectat, st.Stoc as stoc_curent
,*
from istoricstocuri i inner join STOCURI_CORECTATE_ISTORIC s on
i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.pret=i.pret inner join nomencl n on n.cod=s.cod
inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
where i.Cod_gestiune not in ('211','212')
--and st.Stoc
--and i.Stoc<s.stoc
order by (s.Stoc-i.stoc) 

select * from STOCURI_CORECTATE_ISTORIC s WHERE not exists 
(select 1 from istoricstocuri i where i.Cod_gestiune not in ('211','212')
and i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.pret=i.pret )

select * from istoricstocuri i WHERE i.Cod_gestiune not in ('211','212') 
and not exists 
(select 1 from STOCURI_CORECTATE_ISTORIC s where 
	i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.pret=i.pret )
	
	select * from istoricstocuri i where i.Cod_gestiune not in ('211','212') 
	and i.cod like '3305055246080'
	select * from STOCURI_CORECTATE_ISTORIC s where s.cod like '3305055246080'


select *
--into istoricstocuri_initial
from istoricstocuri i
where i.Cod_gestiune not in ('211','212')

select max(n.denumire) as denumire, ISNULL(i.Cod_gestiune,s.Cod_gestiune ) as Cod_gestiune, ISNULL(i.Cod,s.Cod ) as Cod, 
(sum(isnull(s.Stoc,0))-sum(isnull(i.stoc,0))) as dif_cant, sum(isnull(i.Stoc,0)) as stoc_initial,sum(isnull(s.stoc,0)) as stoc_corectat
,SUM(ISNULL(st.stoc,0)) as stoc_curent
--,*
from istoricstocuri_initial i left join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
full outer join STOCURI_CORECTATE_ISTORIC s on
i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.pret=i.pret
left join nomencl n on n.Cod = ISNULL(i.Cod,s.Cod )
where i.Stoc is null or s.stoc is null
GROUP BY ISNULL(i.Cod_gestiune,s.Cod_gestiune ), ISNULL(i.Cod,s.Cod ) 
--having sum(isnull(i.Stoc,0))<sum(isnull(s.stoc,0))
order by (sum(isnull(s.Stoc,0))-sum(isnull(i.stoc,0)))

SELECT Cod_gestiune, s.Cod, count(distinct s.Pret)
FROM istoricstocuri_initial s
group by s.Cod_gestiune, s.Cod
having  count(distinct s.Pret)>1
order by s.Cod_gestiune, s.Cod

select * from STOCURI_CORECTATE_ISTORIC s1 where exists 
(SELECT Cod_gestiune, s.Cod, count(distinct s.Pret)
FROM STOCURI_CORECTATE_ISTORIC s
group by s.Cod_gestiune, s.Cod
having  count(distinct s.Pret)>1 and s.Cod_gestiune=s1.Cod_gestiune and s1.Cod=s.Cod)
order by s1.Cod_gestiune, s1.Cod

select * from STOCURI_CORECTATE_ISTORIC s
where s.Cod not in (select n.cod from nomencl n)

select n.denumire, (s.Stoc-i.stoc) as dif_cant, i.Stoc as stoc_initial,s.stoc as stoc_corectat, st.Stoc as stoc_curent
,*
from istoricstocuri i inner join STOCURI_CORECTATE_ISTORIC s on
i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare inner join nomencl n on n.cod=s.cod
inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
where i.Cod_gestiune not in ('211','212')
--and i.Pret<>s.Pret
--and st.Stoc
--and i.Stoc<s.stoc
order by (s.Stoc-i.stoc) 

--insert istoricstocuri
select * from STOCURI_CORECTATE_ISTORIC s WHERE not exists 
(select 1 from istoricstocuri i where i.Cod_gestiune not in ('211','212')
and i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare)

select * from istoricstocuri i WHERE i.Cod_gestiune not in ('211','212') 
and not exists 
(select 1 from STOCURI_CORECTATE_ISTORIC s where 
	i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare)
	
select n.denumire
, (isnull(s.Stoc,0)-i.stoc) as dif_cant, i.Stoc as stoc_initial,isnull(s.Stoc,0) as stoc_corectat
,st.Intrari,st.Iesiri, st.Stoc as stoc_curent, isnull(s.Stoc,0)-(i.stoc-st.stoc) as stoc_estimat_dupa_corectie_cantitate_cod_intrare
,*
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
left join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
--and i.Pret<>s.Pret
--and st.Stoc
--and i.Stoc>isnull(s.Stoc,0)
and isnull(s.Stoc,0)-(i.stoc-st.stoc)<0
--and (i.stoc-st.stoc)<0
--and i.cod='01350330'
order by (isnull(s.Stoc,0)-i.stoc)

select n.denumire
, (isnull(s.Stoc,0)-i.stoc) as dif_cant, i.Stoc as stoc_initial,isnull(s.Stoc,0) as stoc_corectat
--,st.Intrari,st.Iesiri, st.Stoc as stoc_curent, isnull(s.Stoc,0)-(i.stoc-st.stoc) as stoc_estimat_dupa_corectie_cantitate_cod_intrare
,*
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
--inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
left join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
--and i.Pret<>s.Pret
--and st.Stoc
--and i.Stoc>isnull(s.Stoc,0)
and i.Stoc<>isnull(s.Stoc,0)
--and isnull(s.Stoc,0)+st.Intrari-st.Iesiri>=0
--and (st.Iesiri>0 or st.Intrari>0)
--and (i.stoc-st.stoc)<0
--and i.cod='01350330'
order by (isnull(s.Stoc,0)-i.stoc)

--update istoricstocuri
set stoc=isnull(s.Stoc,0)
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
--inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
left join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
--and i.Pret<>s.Pret
--and st.Stoc
--and i.Stoc>isnull(s.Stoc,0)
and i.Stoc<>isnull(s.Stoc,0)
--and isnull(s.Stoc,0)+st.Intrari-st.Iesiri>=0
--and (st.Iesiri>0 or st.Intrari>0)
--and (i.stoc-st.stoc)<0
--and i.cod='01350330'
--order by (isnull(s.Stoc,0)-i.stoc)

select * from istoricstocuri s WHERE not exists 
(select 1 from istoricstocuri_initial i where i.Cod_gestiune not in ('211','212')
and i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare)
and exists
(select 1 from istoricstocuri i where i.Cod_gestiune not in ('211','212')
and i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod )

--delete istoricstocuri 
from istoricstocuri s WHERE not exists 
(select 1 from istoricstocuri_initial i where i.Cod_gestiune not in ('211','212')
and i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare)
and exists
(select 1 from istoricstocuri i where i.Cod_gestiune not in ('211','212')
and i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod )

--insert istoricstocuri
select * from STOCURI_CORECTATE_ISTORIC s WHERE not exists 
(select 1 from istoricstocuri_initial i where i.Cod_gestiune not in ('211','212')
and i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare)
--and exists
--(select 1 from istoricstocuri i where i.Cod_gestiune not in ('211','212')
--and i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod )

select n.denumire
, (isnull(s.pret,0)-i.pret) as dif_pret,i.pret as pret_initial,isnull(s.pret,0) as pret_corectat
, (isnull(s.Stoc,0)-i.stoc) as dif_cant, i.Stoc as stoc_initial,isnull(s.Stoc,0) as stoc_corectat
,st.Intrari,st.Iesiri, st.Stoc as stoc_curent, isnull(s.Stoc,0)-(i.stoc-st.stoc) as stoc_estimat_dupa_corectie_cantitate_cod_intrare
,*
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
inner join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
and i.Pret<>s.Pret
AND s.Pret>0
--and st.Stoc
--and i.Stoc>isnull(s.Stoc,0)
--and i.Stoc<>isnull(s.Stoc,0)
--and isnull(s.Stoc,0)+st.Intrari-st.Iesiri>=0
--and (st.Iesiri>0 or st.Intrari>0)
--and (i.stoc-st.stoc)<0
--and i.cod='01350330'
order by (isnull(s.pret,0)-i.pret)

select * from STOCURI_CORECTATE WHERE COD='95900158            '

--update istoricstocuri
set Pret=s.Pret
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
inner join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
and i.Pret<>s.Pret
AND s.Pret>0
--and st.Stoc
--and i.Stoc>isnull(s.Stoc,0)
--and i.Stoc<>isnull(s.Stoc,0)
--and isnull(s.Stoc,0)+st.Intrari-st.Iesiri>=0
--and (st.Iesiri>0 or st.Intrari>0)
--and (i.stoc-st.stoc)<0
--and i.cod='01350330'
--order by (isnull(s.pret,0)-i.pret)

select n.denumire
, (isnull(s.Stoc,0)-i.stoc) as dif_cant, i.Stoc as stoc_initial,isnull(s.Stoc,0) as stoc_corectat
,st.Intrari,st.Iesiri, st.Stoc as stoc_curent, isnull(s.Stoc,0)-(i.stoc-st.stoc) as stoc_estimat_dupa_corectie_cantitate_cod_intrare
,*
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
left join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
--and i.Pret<>s.Pret
--and st.Stoc
--and i.Stoc>isnull(s.Stoc,0)
and isnull(s.Stoc,0)-(i.stoc-st.stoc)<0
--and (i.stoc-st.stoc)<0
--and i.cod='01350330'
order by (isnull(s.Stoc,0)-i.stoc)

select n.Denumire
,i.Stoc as stoc_initial,isnull(s.Stoc,0) as stoc_corectat
,i.pret as pret_initial,isnull(s.pret,0) as pret_corectat
 ,* 
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
left join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
and (i.Stoc<>ISNULL(s.stoc,0) or i.pret<>ISNULL(s.Pret,0))

select i.Pret,s.Pret,i.*,s.*
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
inner join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
and i.Pret<>s.Pret
AND s.Pret>0

select n.Denumire
,i.Stoc as stoc_corectat,isnull(st.Stoc,0) as stoc_curent
,i.pret as pret_corectat,isnull(st.pret,0) as pret_curent
 ,* 
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
where i.Cod_gestiune not in ('211','212')
and i.pret<>ISNULL(st.Pret,0)
order by i.Cod_gestiune,i.cod



declare istoc cursor for
select i.subunitate,i.cod_gestiune,i.cod,i.cod_intrare,i.data,i.pret,i.cont
from istoricstocuri i 
where i.Cod_gestiune not in ('211','212')

declare @subunitate varchar(20),@cGest varchar(20), @cCod varchar(20), @cCodI varchar(20), @data datetime, @nPret float,@cContDeStoc varchar(20)
open istoc
fetch next from istoc into @subunitate,@cGest, @cCod, @cCodI, @data, @nPret,@cContDeStoc

while @@FETCH_STATUS=0
begin
	exec yso.inlocuirePretsauContpePozDoc @subunitate,@cGest, @cCod, @cCodI, @data, @nPret,@cContDeStoc
	fetch next from istoc into @subunitate,@cGest, @cCod, @cCodI, @data, @nPret,@cContDeStoc
	print @cGest, @cCod, @cCodI, @data, @nPret
end
	
close istoc
deallocate istoc


select n.denumire
, (isnull(s.Stoc,0)-i.stoc) as dif_cant, i.Stoc as stoc_initial,isnull(s.Stoc,0) as stoc_corectat
,st.Intrari,st.Iesiri, st.Stoc as stoc_curent, isnull(s.Stoc,0)-(i.stoc-st.stoc) as stoc_estimat_dupa_corectie_cantitate_cod_intrare
,*
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
left join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
--and i.Pret<>s.Pret
--and st.Stoc
and i.Stoc<>isnull(s.Stoc,0)
and isnull(s.Stoc,0)-(i.stoc-st.stoc)<0
--and (i.stoc-st.stoc)<0
--and i.cod='01350330'
order by (isnull(s.Stoc,0)-i.stoc)

--update istoricstocuri
set stoc=isnull(s.Stoc,0)
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
inner join stocuri st on st.Cod_gestiune=i.Cod_gestiune and st.Cod=i.Cod and st.Cod_intrare=i.Cod_intrare
left join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
--and i.Pret<>s.Pret
--and st.Stoc
and i.Stoc<>isnull(s.Stoc,0)
and isnull(s.Stoc,0)-(i.stoc-st.stoc)<0
--and (i.stoc-st.stoc)<0
--and i.cod='01350330'
--order by (isnull(s.Stoc,0)-i.stoc)

select n.Denumire
,i.Stoc as stoc_initial,isnull(s.Stoc,0) as stoc_corectat
,i.pret as pret_initial,isnull(s.pret,0) as pret_corectat
 ,* 
from istoricstocuri i 
inner join nomencl n on n.cod=i.cod
left join STOCURI_CORECTATE_ISTORIC s on i.Cod_gestiune=s.Cod_gestiune and s.Cod=i.cod and s.Cod_intrare=i.Cod_intrare 
where i.Cod_gestiune not in ('211','212')
and (i.Stoc<>ISNULL(s.stoc,0) or i.pret<>ISNULL(s.Pret,0))

--truncate table istoricstocuri
--insert istoricstocuri
select * from test..istoricstocuri
select * from STOCURI_LIMITA
select top 0 *
into STOCLIM_STOCURI_LIMITA
from stoclim

----INSERT STOCLIM_STOCURI_LIMITA
SELECT DISTINCT--*,
'1'	--Subunitate	char	9
,'C'	--Tip_gestiune	char	1
,'101'	--Cod_gestiune	char	9
,LEFT(N.CODE_ARTICOL,20)	--Cod	char	20
,'2012-01-01'	--Data	datetime	8
,N.SAFETY_STOC	--Stoc_min	float	8
,0	--Stoc_max	float	8
,0	--Pret	float	8
,''	--Locatie	char	30
	-- SELECT *
FROM STOCURI_LIMITA N
WHERE isnull(nullif(N.SAFETY_STOC,''),0)<>0
and n.CODE_ARTICOL='3-2605              '

select *
-- update s set s.stoc_min=sl.stoc_min
from stoclim s join STOCLIM_STOCURI_LIMITA sl on sl.Subunitate=s.Subunitate and sl.Tip_gestiune=s.Tip_gestiune
and sl.Cod_gestiune=s.Cod_gestiune and sl.Cod=s.Cod and sl.Data=s.Data

---- delete STOCLIM where data<>'2999-12-31' INSERT stoclim
SELECT * FROM STOCLIM_STOCURI_LIMITA sl
where not exists
(select 1 from stoclim s where sl.Subunitate=s.Subunitate and sl.Tip_gestiune=s.Tip_gestiune
and sl.Cod_gestiune=s.Cod_gestiune and sl.Cod=s.Cod and sl.Data=s.Data)

select * from stoclim s where s.Cod not in 
(select n.cod from nomencl n)

select * 
-- update i set Furnizor=n.furnizor
from istoricstocuri i join nomencl n on n.cod=i.cod join terti t on t.tert=n.Furnizor 

select top 0 *
into STOCLIM_STOC_MINIM_PIESE
from stoclim

---- TRUNCATE TABLE STOCLIM_STOC_MINIM_PIESE INSERT STOCLIM_STOC_MINIM_PIESE
SELECT DISTINCT--*,
'1'	--Subunitate	char	9
,'C'	--Tip_gestiune	char	1
,'101'	--Cod_gestiune	char	9
,LEFT(N.COD_ARTICOL,20)	--Cod	char	20
,'2012-01-01'	--Data	datetime	8
,MAX(CONVERT(FLOAT,N.[Stoc minim]))	--Stoc_min	float	8
,0	--Stoc_max	float	8
,0	--Pret	float	8
,''	--Locatie	char	30
	-- SELECT *
FROM STOC_MINIM_PIESE N
WHERE isnull(nullif(N.[Stoc minim],''),0)<>0
group by n.COD_ARTICOL
--and n.CODE_ARTICOL='3-2605              '

SELECT * FROM STOC_MINIM_PIESE

select *
-- update s set s.stoc_min=sl.stoc_min
from stoclim s join STOCLIM_STOC_MINIM_PIESE sl on sl.Subunitate=s.Subunitate and sl.Tip_gestiune=s.Tip_gestiune
and sl.Cod_gestiune=s.Cod_gestiune and sl.Cod=s.Cod and sl.Data=s.Data

---- delete STOCLIM where data<>'2999-12-31' INSERT stoclim
SELECT * FROM STOCLIM_STOC_MINIM_PIESE sl
where not exists
(select 1 from stoclim s where sl.Subunitate=s.Subunitate and sl.Tip_gestiune=s.Tip_gestiune
and sl.Cod_gestiune=s.Cod_gestiune and sl.Cod=s.Cod and sl.Data=s.Data)

select * from STOCLIM_STOC_MINIM_PIESE s where s.Cod not in 
(select n.cod from nomencl n)

select * 
-- update i set Furnizor=n.furnizor
from istoricstocuri i join nomencl n on n.cod=i.cod join terti t on t.tert=n.Furnizor 

select top 0 *
--INTO NOMENCL_STOC_MINIM_PIESE
FROM NOMENCL

-- TRUNCATE TABLE NOMENCL_STOC_MINIM_PIESE INSERT NOMENCL_STOC_MINIM_PIESE
SELECT
LEFT(N.COD_ARTICOL,20)	--Cod	char	20
,'M'	--Tip	char	1
,LEFT(MAX(N.DESCRIERE_ARTICOL),150)	--Denumire	char	150
,'BUC'	--UM	char	3
,''	--UM_1	char	3
,''	--Coeficient_conversie_1	float	8
,''	--UM_2	char	20
,''	--Coeficient_conversie_2	float	8
,'371.1'	--Cont	char	13
,''	--Grupa	char	13
,''	--Valuta	char	3
,''	--Pret_in_valuta	float	8
,''	--Pret_stoc	float	8
,''	--Pret_vanzare	float	8
,''	--Pret_cu_amanuntul	float	8
,24	--Cota_TVA	real	4
,''	--Stoc_limita	float	8
,''	--Stoc	float	8
,''	--Greutate_specifica	float	8
,LEFT(MAX(N.BRAND),13)	--Furnizor	char	13
,''	--Loc_de_munca	char	150
,''	--Gestiune	char	13
,''	--Categorie	smallint	2
,''	--Tip_echipament	char	21
	--SELECT *
FROM STOC_MINIM_PIESE N
group by n.COD_ARTICOL


-- insert nomencl
select * from NOMENCL_STOC_MINIM_PIESE ns where ns.cod not in 
(select n.cod from nomencl n)
