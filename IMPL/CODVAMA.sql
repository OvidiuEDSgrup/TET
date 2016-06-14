--drop table COD_VAMA_ASIS
SELECT --TOP 0 
* 
--INTO COD_VAMA_ASIS
FROM codvama WHERE COD LIKE 'TEST%'

--TRUNCATE TABLE COD_VAMA_ASIS
--INSERT COD_VAMA_ASIS
SELECT --*,
LEFT(C.[Atribut vamal],20)	--Cod	char	20
,''	--Denumire	char	150
,MAX(LEFT(C.COD_UNIT_MAS,3))	--UM	char	3
,''	--UM2	char	3
,0	--Coef_conv	float	8
,0	--Taxa_UE	real	4
,0	--Taxa_AELS	real	4
,0	--Taxa_GB	real	4
,0	--Taxa_alte_tari	real	4
,0	--Comision_vamal	real	4
,0	--Randament	float	8
,MAX(RTRIM(LEFT(C.COD,30))) --+LTRIM(ISNULL(CONVERT(CHAR,NULLIF(ROW_NUMBER() OVER(PARTITION BY COD ORDER BY DENUMIRE),1)),''))	--Alfa1	char	20
,MAX(LEFT(C.UNIT_GREUTATE,20))	--Alfa2	char	20
,0	--Val1	float	8
,0	--Val2	float	8
	--SELECT max(len(denumire))
FROM COD_VAMA C
where LEFT(C.[Atribut vamal],20) LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]%'
GROUP BY C.[Atribut vamal]

--TRUNCATE TABLE codvama
--INSERT codvama
select * from COD_VAMA_ASIS

select * from COD_VAMA_ASIS c
where c.Cod in 
(select c.cod from COD_VAMA_ASIS c 
group by c.Cod
having COUNT(*)>1)
